class CreateSnapshotJob
  def perform
    puts 'create_snapshot job started'
    EventLog.log_event(message: 'create_snapshot job started', event_type_name: 'CREATE_SNAPSHOT_JOB' )

    date  = Time.now.strftime('%Y-%m-%d')
    puts "Running with CID=1, date=#{date}"
    CdsUtilHelper.cache_delete_all
    CreateSnapshotHelper::create_company_snapshot_by_weeks(1, date, true)

    EventLog.log_event(message: 'create_snapshot job completed', event_type_name: 'CREATE_SNAPSHOT_JOB')
  end

  def error(job, ex)
    msg = "CreateSnapshotJob error: #{ex.message[0..1000]}"
    puts msg
    EventLog.log_event(message: msg, event_type_name: 'CREATE_SNAPSHOT_JOB')
    puts ex.backtrace
  end

  def failure(job)
    msg = 'CreateSnapshotJob failure'
    puts msg
    EventLog.log_event(message: msg, event_type_name: 'CREATE_SNAPSHOT_JOB')
  end
end
