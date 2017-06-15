namespace :db do
  desc 'mark_errors_on_scheduled_tasks'
  task mark_errors_on_scheduled_tasks: :environment do
    t_id = ENV['ID'].to_i
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        start_job(t_id) if t_id != 0
        ScheduledApiClientTask.all.each(&:change_status_to_error_if_expired)
        finish_job(t_id) if t_id != 0
      rescue => _e
        finish_job_with_error(t_id) if t_id != 0
        raise ActiveRecord::Rollback
      end
    end
  end
end
