require './app/helpers/jobs_helper.rb'
include JobsHelper
namespace :db do
  desc 'archive_scheduled_tasks'

  def archive_tasks_if_job_done_or_error
    jobs_queue_ids = ScheduledApiClientTask.all.pluck(:jobs_queue_id).uniq.compact
    jobs_queue_ids.each do |id|
      if ScheduledApiClientTask.job_done? id
        ScheduledApiClientTask.archive_by_job_queue_id id
        JobsQueue.find(id).job.end_job
      elsif ScheduledApiClientTask.job_error? id
        ScheduledApiClientTask.archive_by_job_queue_id id
        JobsQueue.find(id).job.terminate_job_with_error_status(JobsQueue::FINISHED_WITH_ERROR)
      end
    end
  end

  def archive_tasks_with_no_jobs
    ScheduledApiClientTask.where(jobs_queue_id: nil).each do |t|
      if t.done? || t.error?
        t.archive
        t.delete
      end
    end
  end

  task archive_scheduled_tasks: :environment do
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    t_id = ENV['ID'].to_i
    ActiveRecord::Base.transaction do
      begin
        start_job(t_id) if t_id != 0
        archive_tasks_with_no_jobs
        archive_tasks_if_job_done_or_error
        finish_job(t_id) if t_id != 0
      rescue => e
        finish_job_with_error(t_id) if t_id != 0
        raise ActiveRecord::Rollback
      end
    end
  end
end
