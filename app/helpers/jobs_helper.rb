module JobsHelper

  JOB_INTERVALS_DAILY  ||= 'daily'
  JOB_INTERVALS_WEEKLY ||= 'weekly'
  JOB_INTERVALS_HOURLY ||= 'hourly'

  COLLECTOR_QUEUE ||= 'collector_queue'
  APP_QUEUE       ||= 'app_queue'

  def self.get_jobs_list
    return [
      {job: CollectorJob,      interval: JOB_INTERVALS_HOURLY, interval_offset: 0, queue: COLLECTOR_QUEUE},
      {job: AlertsJob,         interval: JOB_INTERVALS_DAILY,  interval_offset: 0, queue: APP_QUEUE},
      {job: CreateSnapshotJob, interval: JOB_INTERVALS_WEEKLY, interval_offset: 0, queue: APP_QUEUE},
      {job: PrecalculateJob,   interval: JOB_INTERVALS_WEEKLY, interval_offset: 1, queue: APP_QUEUE},
    ]
  end

  def self.schedule_delayed_jobs
    puts('Schedule delayed jobs start')
    jobsarr = JobsHelper.get_jobs_list
    jobsarr.each do |job|
      if job[:interval] == JOB_INTERVALS_HOURLY
        schedule_hourly_job(job[:job], job[:queue])
      elsif job[:interval] == JOB_INTERVALS_DAILY
        schedule_daily_job(job[:job], job[:queue], job[:interval_offset])
      elsif job[:interval] == JOB_INTERVALS_WEEKLY
        schedule_weekly_job(job[:job], job[:queue], job[:interval_offset])
      else
        raise "Illegal job interval type: #{job[:interval]}"
      end
    end

    #create_historical_data_job

    puts('Schedule delayed jobs done')
  end

  def self.schedule_hourly_job(job, queue)
    (0..23).each do |h|
      hourstart = h.hours.from_now.beginning_of_hour
      hourend   = h.hours.from_now.end_of_hour
      jobs = Delayed::Job
               .where("handler like '%#{job.to_s}%'")
               .where(run_at: hourstart .. hourend)
      next if jobs.count > 0
      Delayed::Job.enqueue(job.new, queue: queue, run_at: h.hours.from_now)
    end
  end

  ####################################################################
  # Check if there's such a job in the next 7 days, if not will
  # schedule it.
  # offset is 0-6 starting Sunday
  ####################################################################
  def self.schedule_weekly_job(job, queue='defaultqueue', dayofweek=0)
    byebug
    wday = Date.today.wday
    if wday <= dayofweek
      next_job_run_at = Date.today - wday + dayofweek
    else
      next_job_run_at = Date.today + 7 - wday + dayofweek
    end

    jobs = Delayed::Job
           .where("handler like '%#{job.to_s}%'")
           .where(run_at: next_job_run_at)
    return if jobs.count > 0
    Delayed::Job.enqueue(job.new, queue: queue, run_at: next_job_run_at)
  end

  ####################################################################
  # Check if there's such a job tomorrow, if not will
  # schedule it.
  # offset is 0-23 starting Sunday
  ####################################################################
  def self.schedule_daily_job(job, queue='defaultqueue', hourofday=0)
    beginning_of_day = 1.day.from_now.at_beginning_of_day
    end_of_day       = 1.day.from_now.at_end_of_day

    jobs = Delayed::Job
           .where("handler like '%#{job.to_s}%'")
           .where(run_at: beginning_of_day..end_of_day)
    return if jobs.count > 0

    next_job_run_at = beginning_of_day + hourofday.hours
    Delayed::Job.enqueue(
      job.new,
      queue: queue,
      run_at: next_job_run_at)
  end

  #####################################################################
  # Create a job for the initial push operation
  #####################################################################
  def create_historical_data_job
    return if Company.find(1).setup_state != 'push'
    Delayed::Job.enqueue(
      HistoricalDataJob.new,
      queue: APP_QUEUE,
      run_at: Time.now)
  end

  def self.jobs_status
    sqlstr = "
      SELECT handler, MIN(run_at)
      FROM delayed_jobs
      GROUP BY handler"
    res = ActiveRecord::Base.connection.exec_query(sqlstr)
    ret = {}
    res.as_json.each do |e|
      job_name = e['handler'].split(':')[1].split(' ')[0]
      ret[job_name] = {
        name: job_name,
        next_run: e['min'][0..15]
      }
    end

    precalc_status = get_single_job_status(
                                 'PRECALCULATE_JOB: precalaculate job started',
                                 'PRECALCULATE_JOB: precalaculate job completed',
                                 'PRECALCULATE_JOB: precalaculate job error:%')
    ret['PrecalculateJob'][:job_status] = precalc_status

    create_snapshot_status = get_single_job_status(
                                'CREATE_SNAPSHOT_JOB: create_snapshot job started',
                                'CREATE_SNAPSHOT_JOB: create_snapshot job completed',
                                'CREATE_SNAPSHOT_JOB: create_snapshot job error:%')
    ret['CreateSnapshotJob'][:job_status] = create_snapshot_status

    alerts_status = get_single_job_status(
                                'ALERTS_JOB: create_alerts job started',
                                'ALERTS_JOB: create_alerts job completed',
                                'ALERTS_JOB: create_alerts job error:%')
    ret['AlertsJob'][:job_status] = alerts_status

    collector_status = get_single_job_status(
                                'COLLECTOR(1)-INFO - start run',
                                'COLLECTOR(1)-INFO - end run',
                                'COLLECTOR(1)-ERROR - %')
    ret['CollectorJob'][:job_status] = collector_status

    return ret
  end

  ###################################################################
  # Determine when did a job run and for how long
  ###################################################################
  def self.get_single_job_status(start_msg, end_msg, err_msg)
    s = EventLog.where(message: start_msg).last

    if s.nil?
      return "Never ran"
    end
    start_time = s.created_at

    e   = EventLog.where(message: end_msg)
                  .where("created_at > '#{start_time.utc.strftime('%Y-%m-%d %H:%M:%S')}'")
                  .last
    err = EventLog.where("message like '#{err_msg}'")
                  .where("created_at > '#{start_time.utc.strftime('%Y-%m-%d %H:%M:%S')}'")
                  .last

    if !err.nil?
      error_time = err.created_at.strftime('%Y-%m-%d %H:%M')
      error = err.message
      return "Finished at: #{error_time} with error: #{error}"
    end

    if !e.nil?
      finish_time = e.created_at
      duration = (finish_time - start_time) / 60
      finish_time = finish_time.strftime('%Y-%m-%d %H:%M')
      return "Last finished at: #{finish_time}, after: #{duration.round} minutes"
    end
    return "Started at: #{start_time} and still running"
  end
end

