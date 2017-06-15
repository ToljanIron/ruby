module JobsHelper
  LIMIT = 20

  def start_job(id)
    job = Job.find(id)
    EventLog.log_event(event_type_name: 'JOB_STARTED', job_id: job.id,  message: job.name)
    job.start_job
    job
  end

  def finish_job(id)
    job = Job.find(id)
    EventLog.log_event(event_type_name: 'JOB_DONE', job_id: job.id,  message: job.name)
    job.end_job
    job
  end

  def finish_job_with_error(id)
    job = Job.find(id)
    EventLog.log_event(event_type_name: 'JOB_FAIL', job_id: job.id, message: job.name)
    job.terminate_job_with_error_status(JobsQueue::FINISHED_WITH_ERROR)
    job
  end

  def schedule_new_jobs
    Job.get_jobs_to_be_run(LIMIT).each do |j|
      schedule_job(j)
    end
  end

  def schedule_new_system_jobs
    Job.get_jobs_to_be_run(LIMIT, DateTime.now.in_time_zone, Job::SYSTEM_JOB).each do |j|
      EventLog.log_event(event_type_name: 'SCHEDULE_JOB', job_id: j.id, message: j.name)
      schedule_job(j)
    end
  end

  def archive_jobs
    jobs = Job.get_jobs_queues_with_status(JobsQueue::ENDED, LIMIT, false)
    archive_old_jobs_queues(jobs)
    jobs = Job.get_jobs_queues_with_status(JobsQueue::FINISHED_WITH_ERROR, LIMIT, false)
    archive_old_jobs_queues(jobs)
    jobs = Job.get_jobs_queues_with_status(JobsQueue::ENDED, LIMIT, false, Job::SYSTEM_JOB)
    archive_old_jobs_queues(jobs)
    jobs = Job.get_jobs_queues_with_status(JobsQueue::FINISHED_WITH_ERROR, LIMIT, false, Job::SYSTEM_JOB)
    archive_old_jobs_queues(jobs)
  end

  def archive_jobs_that_should_have_ended(now = DateTime.now)
    Job.get_jobs_queues_that_should_have_ended(LIMIT, now).each do |q|
      archive_queues_if_did_not_end_in_time(q.job, q)
    end
  end

  def archive_queues_if_did_not_end_in_time(job, job_queue)
    ActiveRecord::Base.transaction do
      job_queue.status = JobsQueue::KILLED_ERROR_DID_NOT_RUN if job_queue.status == JobsQueue::PENDING
      job_queue.status = JobsQueue::KILLED_ERROR_DID_NOT_FINISH_IN_TIME if job_queue.status == JobsQueue::RUNNING
      job_queue.save!
      job.archive_jobs(Job::ARCHIVE_OLD)
    end
  end

  def archive_old_jobs_queues(jobs)
    jobs.each do |j|
      EventLog.log_event(event_type_name: 'JOB_ARCHIVED', job_id: j.id, message: j.name)
      j.archive_jobs(Job::ARCHIVE_OLD)
    end
  end

  def schedule_job(job)
    return false unless job.should_run?
    job_status = job.job_status
    return false if job_status == JobsQueue::PENDING || job_status == JobsQueue::RUNNING
    job.create_job
  end
end
