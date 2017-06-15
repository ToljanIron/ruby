namespace :db do
  require './app/helpers/invalid_state_error_helper.rb'
  require 'date'
  include InvalidStateErrorHelper
  desc 'invalid_state_error_tasks'
  task invalid_state_error_tasks: :environment do
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    t_id = ENV['ID'].to_i
    ActiveRecord::Base.transaction do
      begin
        start_job(t_id) if t_id != 0
        eventlog_invalid_state_insertion
        invalid_dates_detector(Time.zone.now - 3.months, 24, 1, Time.zone.now)
      rescue => _e
        finish_job_with_error(t_id) if t_id != 0
        raise ActiveRecord::Rollback
      end
    end
  end
end
