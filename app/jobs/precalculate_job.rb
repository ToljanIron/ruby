class PrecalculateJob
  def perform
    puts 'precalculate job started'
    EventLog.log_event(message: 'precalaculate job started', event_type_name: 'PRECALCULATE_JOB' )

    cid = 1
    sid = Snapshot.where(company_id: cid).last.id if sid == '-1'

    [700,701,702,703,704,705,706,707,709,200,201,203,204,205,206,207,300,301,302,303].each do |aid|
      PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_scores(cid, -1, -1, aid, sid, true)
    end
    PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_gauges(cid, sid, true)
    PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_measures(cid, sid, true)

    EventLog.log_event(message: 'preclculate job completed', event_type_name: 'PRECALCULATE_JOB')
  end

  def error(job, ex)
    msg = "precalaculate job error: #{ex.message[0..1000]}"
    puts msg
    EventLog.log_event(message: msg, event_type_name: 'PRECALCULATE_JOB')
    puts ex.backtrace
  end

  def failure(job)
    msg = 'precalaculate job failure'
    puts msg
    EventLog.log_event(message: msg, event_type_name: 'PRECALCULATE_JOB')
  end
end
