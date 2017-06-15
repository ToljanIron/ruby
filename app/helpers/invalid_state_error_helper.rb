module InvalidStateErrorHelper
  ## This check is invalid - error described in: us21872
  def invalid_snapshot_detector
    query = 'select sn.company_id
            from snapshots as sn
            left join metric_scores as ms on sn.id = ms.snapshot_id
            where ms.snapshot_id IS NULL'
    array_of_empty_snapshots = []
    ActiveRecord::Base.connection.execute(query).each { |hash| array_of_empty_snapshots.push(hash['company_id'].to_i) }
    return array_of_empty_snapshots
  end

  def unprocessed_rows_detector
    comps_that_have_unprocessed_rows = []
    snapshot_company_ids = Snapshot.all.pluck(:company_id).uniq
    snapshot_company_ids.each do |comp_id|
      unprocessed_entries_per_company = RawDataEntry.all.select { |entry| entry.company_id == comp_id && entry.processed == false }
      unprocessed_entries_per_company.sort_by(&:date)
      snapshots_per_comp_id = Snapshot.all.select { |entry| entry.company_id == comp_id }
      snapshots_per_comp_id.sort_by(&:timestamp)
      comps_that_have_unprocessed_rows.push(comp_id) unless unprocessed_entries_per_company.nil?|| unprocessed_entries_per_company.empty? || unprocessed_entries_per_company.first.date > snapshots_per_comp_id.last.created_at
    end
    return comps_that_have_unprocessed_rows
  end

  def eventlog_invalid_state_insertion
    EventLog.log_event(message: 'invalid state detector start working')
    if unprocessed_rows_detector.empty? && invalid_snapshot_detector.empty?
      EventLog.log_event(message: 'invalid state detector did not find invalid snapshots')
      return
    end
    final_log = 'the problematic companys are ' + (unprocessed_rows_detector + invalid_snapshot_detector).to_s
    EventLog.log_event(message: final_log)
  end

  def invalid_dates_detector(start_date, delta, amount_to_find_for_each_delta, stop_date)
    return nil unless start_date <= stop_date
    diff = start_date + delta.hours
    return diff unless amount_to_find_for_each_delta == RawDataEntry.where(date: start_date..diff).limit(amount_to_find_for_each_delta).count
    start_date = diff
    return invalid_dates_detector(start_date, delta, amount_to_find_for_each_delta, stop_date)
  end
end
