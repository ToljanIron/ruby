include ScheduledApiClientTasksHelper
require 'abstract_api_client_task'
class ScheduledApiClientTask < AbstractApiClientTask
  DEFAULT_EXPIRATION_DELTA = 1.day
  validates :expiration_date, presence: true

  scope :by_jobs_queue_id, ->(jobs_queue_id) { where(jobs_queue_id: jobs_queue_id) }

  def self.create_scheduled_task(api_client_task_definition_id, jobs_queue_id, params = nil, api_client_id = nil, expiration_date = nil)
    return nil unless ScheduledApiClientTasksHelper.vaild_api_client_task?(api_client_task_definition_id)
    # return nil unless ScheduledApiClientTasksHelper.vaild_jobs_queue?(jobs_queue_id)
    return nil if api_client_id && !ScheduledApiClientTasksHelper.valid_client?(api_client_id)
    api_client_id = ApiClient.first.id if api_client_id.nil? && ApiClient.count == 1
    expiration_date = Time.now + DEFAULT_EXPIRATION_DELTA unless expiration_date
    res = create!(
      api_client_task_definition_id: api_client_task_definition_id,
      jobs_queue_id: jobs_queue_id,
      params: params,
      api_client_id: api_client_id,
      status: :pending,
      expiration_date: expiration_date
    )
    return res
  end

  def self.job_done?(jobs_queue_id)
    tasks = by_jobs_queue_id(jobs_queue_id)
    tasks.each { |t| return false unless t.done? }
    return true
  end

  def self.job_error?(jobs_queue_id)
    tasks = by_jobs_queue_id(jobs_queue_id)
    tasks.each { |t| return true if t.error? }
    return false
  end

  def self.archive_by_job_queue_id(job_queue_id)
    ActiveRecord::Base.transaction do
      begin
        tasks = by_jobs_queue_id(job_queue_id)
        tasks.each do |t|
          t.archive
          t.delete
        end
      rescue
        # TODO: write to event log
        ActiveRecord::Rollback
      end
    end
  end

  def self.next_task(api_client_id)
    priority = ScheduledApiClientTask.statuses['priority']
    t = ScheduledApiClientTask.where(api_client_id: api_client_id).where(status: priority).order(:id).first
    unless t
      pending = ScheduledApiClientTask.statuses['pending']
      t = ScheduledApiClientTask.where(api_client_id: api_client_id).where(status: pending).order(:id).first
    end
    t.running! if t
    return t
  end

  def assign_to_api_client(api_client_id)
    fail 'assign_to_api_client: failed to assign task to client' unless ScheduledApiClientTasksHelper.valid_client?(api_client_id)
    update(api_client_id: api_client_id)
  end

  def change_status_to_error_if_expired
    self.error! if expired?
  end

  def change_status_to_done
    fail "change_status_to_done: from #{status} to done" unless running?
    self.done!
  end

  def expired?
    return Time.now > expiration_date
  end

  def archive
    ArchivedApiClientTask.transaction do
      ArchivedApiClientTask.create!(
        api_client_task_definition_id: api_client_task_definition_id,
        status: status,
        params: params,
        jobs_queue_id: jobs_queue_id,
        api_client_id: api_client_id
        )
    end
  end
end
