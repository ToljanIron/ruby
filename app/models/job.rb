require 'rake'

class Job < ActiveRecord::Base
  validates :name, presence: true
  validates :reoccurrence_id, presence: true

  attr_accessor :mock_now

  has_many :dependent_jobs, class_name: 'Job'

  belongs_to :company
  belongs_to :reoccurrence
  belongs_to :job_to_api_client_task_convertor

  has_many :jobs_queues
  has_many :jobs_archives

  SYSTEM_JOB = 1
  CLIENT_JOB = 2

  def self.create_new_job(name, company, reoccurrence, type, params = nil)
    job = Job.create!(name: name, company: company, reoccurrence: reoccurrence, type_number: type, next_run: DateTime.now.strftime('%Y-%m-%d %H:%M:%S'), params: params)
    fail 'Failed to create job' if job.id.nil?
    job
  end

  def self.make_me_a_job
    Job.create_new_job('Test Job', Company.first, Reoccurrence.create_new_occurrence(Reoccurrence::HOUR_MINUTES, Reoccurrence::HOUR_MINUTES), Job::CLIENT_JOB)
  end

  def self.get_jobs_to_be_run(limit, now = DateTime.now.in_time_zone, type_number = CLIENT_JOB)
    jobs = Job.where(type_number: type_number).where('next_run <= ?', now).where('job_id is NULL').limit(limit)
    return jobs
  end

  ### returns jobs or returns queues by job ([[queues for job 1], [queues for job 2], [queues for job 3]])
  def self.get_jobs_queues_with_status(status, limit, open_to_queues = true, type_number = CLIENT_JOB)
    jobs = Job.where(type_number: type_number).joins(:jobs_queues).where('jobs_queues.status = ?', status).limit(limit)
    return jobs unless open_to_queues
    queues = []
    jobs.each do |j|
      queues_for_job = []
      j.jobs_queues.each do |q|
        queues_for_job.push(q) if q.status == status
      end
      queues.push(queues_for_job)
    end
    queues
  end

  ### returns jobs or returns a list of queues, each one has a uniqe job
  def self.get_jobs_queues_that_should_have_ended(limit, now = DateTime.now, open_to_queues = true)
    jobs = Job.joins(:jobs_queues).joins(:reoccurrence)
           .where('jobs_queues.status = ? or jobs_queues.status = ?', JobsQueue::RUNNING, JobsQueue::PENDING)
           .where(date_offset_string + " <= ?", now).limit(limit)
    return jobs unless open_to_queues
    queues = []
    jobs.each do |j|
      queues.push(j.current_job_queue)
    end
    queues
  end

  def self.date_offset_string
    return "jobs_queues.updated_at + interval '1 minute' * reoccurrences.fail_after_by_minutes" if using_postgresql?
    return "dateadd(minute, reoccurrences.fail_after_by_minutes, jobs_queues.updated_at)"
  end

  def self.using_postgresql?
    !ActiveRecord::Base.connection.instance_values['config'].nil?
  end

  def does_pass_dont_schedule_constraint?
    return true if dont_schedule_if_working_job_id.nil?
    job = Job.find(dont_schedule_if_working_job_id)
    status = job.job_status
    return false if status == JobsQueue::PENDING || status == JobsQueue::RUNNING
    return true
  end

  def add_dont_schedule_constraint_becuase_of(job)
    self.dont_schedule_if_working_job_id = job.id
    save!
  end

  def add_as_depeendent_of(job)
    self.job_id = job.id
    save!
  end

  def job_status
    if current_job_queue.nil?
      instance = jobs_queues.order('updated_at ASC').first
      return JobsQueue::NOT_SCHEDULED if instance.nil?
      return instance.status
    end
    current_job_queue.status
  end

  def create_job
    fail "Cannot start another job, until the previous one is archived or ended or killed for #{id}" unless current_job_queue.nil?
    ActiveRecord::Base.transaction do
      return false unless does_pass_dont_schedule_constraint?
      JobsQueue.create_job_instance(self)
      self.next_run = DateTime.now + reoccurrence.run_every_by_minutes.minutes
      self.save!
    end
    run_system_job_if_needed
  end

  def start_job
    fail_if_no_job_is_running_or_pending
    EventLog.log_event(event_type_name: 'JOB_STARTED', job_id: id)
    change_job_status JobsQueue::RUNNING
  end

  def end_job
    fail_if_no_job_is_running_or_pending
    change_job_status JobsQueue::ENDED
    EventLog.log_event(event_type_name: 'JOB_DONE')
    Job.create_dependent_jobs(self)
  end

  def job_failed_message(status)
    status = "Job failed #{id}-#{name} with status #{status}"
    EventLog.log_event(event_type_name: 'JOB_FAIL', job_id: id, message: status)
    return ['JOB_FAIL', ': ', status].join
  end

  def terminate_job_with_error_status(status)
    fail_if_no_job_is_running_or_pending
    EventLog.log_event(event_type_name: 'JOB_FAIL', job_id: id, message: status)
    change_job_status status
  end

  ARCHIVE_ALL = 1
  ARCHIVE_ACTIVE = 2
  ARCHIVE_OLD = 3

  def archive_jobs(archive_type)
    ActiveRecord::Base.transaction do
      queues = jobs_queues if archive_type == ARCHIVE_ALL
      queues = [current_job_queue] if archive_type == ARCHIVE_ACTIVE
      queues = old_job_queue if archive_type == ARCHIVE_OLD
      queues.each do |j|
        JobsArchive.create_job_archive(j)
        j.delete
      end
    end
  end

  def job_should_have_ended?
    fail_if_no_job_is_running_or_pending
    job_instance = current_job_queue
    last_updated = job_instance.updated_at
    return (last_updated + reoccurrence.fail_after_by_minutes.minutes) <= now
  end

  def should_run?
    next_run <= now
  end

  def now
    return DateTime.now if mock_now.nil?
    mock_now
  end

  def current_job_queue
    jobs_queues.where('status = ? or status = ?', JobsQueue::PENDING, JobsQueue::RUNNING).first
  end

  def run_system_job_if_needed
    return false unless type_number == SYSTEM_JOB
    return call_rake "#{name}#{params}" if params
    return call_rake name
  end

  def call_rake(task)
    options = {}
    options[:rails_env] = Rails.env
    options[:id] = id
    Delayed::Job.enqueue(DelayedRake.new(task, options))
    return true
  rescue
    EventLog.log_event(event_type_name: 'JOB_FAIL', job_id: id)
    return false
  end

  private

  def self.create_dependent_jobs(job)
    job.dependent_jobs.each(&:create_job)
  end

  def change_job_status(status)
    job_instance = current_job_queue
    job_instance.status = status
    job_instance.save!
  end

  def fail_if_no_job_is_running_or_pending
    fail "No job is running for #{id}" if current_job_queue.nil? || !current_job_queue.running_or_pending?
  end

  def old_job_queue
    jobs_queues.where('status != ? and status != ?', JobsQueue::PENDING, JobsQueue::RUNNING)
  end
end
