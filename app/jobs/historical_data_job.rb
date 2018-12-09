class HistoricalDataJob
  def perform
    puts 'Historical data job started'
    EventLog.log_event(message: 'historical_data job started')
    AnalyzeHistoricalDataHelper.run(1)
    EventLog.log_event(message: 'historical job completed')
  end

  def error(job, ex)
    msg = "HistoricalDataJob error: #{ex.message}"
    puts msg
    EventLog.log_event(message: msg)
    puts ex.backtrace
  end

  def failure(job)
    msg = 'HistoricalDataJob failure'
    puts msg
    EventLog.log_event(message: msg)
  end
end
