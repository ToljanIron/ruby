module PrecalculateMetricScoresHelper
  require './app/helpers/calculate_measure_helper.rb'
  include CalculateMeasureHelper

  NO_PIN = -1
  NO_GROUP = -1
  NO_SNAPSHOT = -1
  NO_COMPANY = -1

  def calculate_scores(cid, gid = -1, pid = -1, mid = -1, sid = -1, rewrite = false)
    fail 'Ambiguous sub-group request with both pin-id and group-id' if gid != NO_GROUP && pid != NO_PIN
    metrics = mid == -1 ? Metric.all : Metric.where(id: mid)
    fail 'No metrics found!' if metrics.empty?
    companies = cid == NO_COMPANY ? find_companies(gid, pid, sid) : Company.where(id: cid)
    fail 'No company found!' if companies.empty?
    values = []
    companies.each do |c|
      snapshots = sid == NO_SNAPSHOT ? Snapshot.where(company_id: c.id) : Snapshot.where(id: sid, company_id: c.id)
      last_snapshot_id = Snapshot.where(company_id: c.id).order('id ASC').last.id
      metrics.each do |m|
        fail 'No snapshots found!' if snapshots.empty?
        snapshots.each do |s|
          # skip for flag if not the last snapshot
          next if m[:metric_type] == 'flag' && s.id != last_snapshot_id && !rewrite
          values += save_metric_for_structure(c.id, s.id, gid, pid, m.id)
        end
      end
    end

    bulk_values = values.each_slice(998).to_a
    bulk_values.each do |sub_values|
      columns = %w(company_id employee_id group_id pin_id snapshot_id metric_id score subgroup_id)
      query = "INSERT INTO metric_scores (#{columns.join(', ')}) VALUES #{sub_values.map { |r| '(' + r.join(',') + ')' }.join(', ')}"
      ActiveRecord::Base.connection.execute(query) if sub_values.any?
    end
  rescue => e
    puts "EXCEPTION at calculate_scores: #{e.message}"
    puts e.backtrace
    raise 'EXCEPTION at calculate_scores: #{e.message}'
  end

  def find_companies(gid, pid, sid)
    if gid != NO_GROUP
      cid = Group.find(gid)[:company_id]
    elsif pid != NO_PIN
      cid = Pin.find(pid)[:company_id]
    elsif sid != NO_SNAPSHOT
      cid = Snapshot.find(sid)[:company_id]
    end
    return Company.where(id: cid) if cid
    return Company.all
  end

  def save_metric_for_structure(cid, sid, gid, pid, mid)
    values = []
    metric = Metric.find(mid)
    # company, all its groups and pins
    if gid == NO_GROUP && pid == NO_PIN
      values += calculate_with_no_group_and_no_pin(cid, sid, mid, metric)
    # group
    elsif gid != NO_GROUP
      fail 'No group found!' if Group.where(id: gid, company_id: cid).empty?
      MetricScore.where(company_id: cid, group_id: gid, snapshot_id: sid, metric_id: mid).delete_all
      values += calculate_and_save_metric_scores(cid, sid, pid, gid, metric)
    # pin
    elsif pid != NO_PIN
      fail 'No pin found!' if Pin.where(id: pid, company_id: cid).empty?
      if metric.metric_type != 'group_measure'
        MetricScore.where(company_id: cid, pin_id: pid, snapshot_id: sid, metric_id: mid).delete_all
        pin_to_calculate = Pin.where(id: pid).first
        pin_to_calculate.update_attribute(:status, :in_progress)
        values += calculate_and_save_metric_scores(cid, sid, pid, gid, metric)
        pin_to_calculate.update_attribute(:status, :saved)
      end
    end
    # puts "#{metric_type} saved"
    return values
  end

  def calculate_with_no_group_and_no_pin(cid, sid, mid, metric)
    values = []
    MetricScore.where(company_id: cid, snapshot_id: sid, metric_id: mid).delete_all
    company_groups = Group.where(company_id: cid)
    company_pins = Pin.where(company_id: cid)
    company_groups.each do |group|
      next if Group.find(group.id).extract_employees.empty? && metric.metric_type != 'group_measure'
      values += calculate_and_save_metric_scores(cid, sid, NO_PIN, group.id, metric)
    end
    company_pins.each do |pin|
      next if EmployeesPin.where(pin_id: pin.id).empty? || metric.metric_type == 'group_measure'
      pin.update_attribute(:status, :in_progress)
      values += calculate_and_save_metric_scores(cid, sid, pin.id, NO_GROUP, metric)
      pin.update_attribute(:status, :saved)
    end
    values += calculate_and_save_metric_scores(cid, sid, NO_PIN, NO_GROUP, metric)
    return values
  end

  def calculate_and_save_metric_scores(cid, sid, pid, gid, metric)
    values = []
    case metric.metric_type
    when 'measure'
      calculated = calculate_measure_scores(cid, sid, pid, gid, metric.index)
    when 'flag'
      calculated = calculate_flags(cid, sid, pid, gid, metric.index)
    when 'analyze'
      calculated = calculate_analyze_scores(cid, sid, pid, gid, metric.index)
    when 'group_measure'
      calculated = calculate_group_measure_scores(sid, metric.index, gid)
    else
      calculated = []
    end
    pid = nil if pid == NO_PIN
    gid = nil if gid == NO_GROUP
    calculated.each do |obj|
      row = []
      [cid, obj[:id].to_i, gid, pid, sid, metric.id, (obj[:measure] || 1.00).to_f, obj[:group_id]].each do |v|
        row.push(v || 'null')
      end
      values.push row
    end
    return values
  end
end
