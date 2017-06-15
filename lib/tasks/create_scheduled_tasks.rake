namespace :db do
  desc 'create_scheduled_tasks'
  task create_scheduled_tasks: :environment do
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    t_id = ENV['ID'].to_i
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        start_job(t_id) if t_id != 0
        limit = 20
        jobs_queue = Job.get_jobs_queues_with_status(JobsQueue::PENDING, limit).flatten
        jobs_queue.each do |jq|
          jq.job.job_to_api_client_task_convertor.convert(jq.id)
          jq.job.start_job
        end
        finish_job(t_id) if t_id != 0
      rescue => e
        finish_job_with_error(t_id) if t_id != 0
        raise ActiveRecord::Rollback
      end
    end
  end
end
