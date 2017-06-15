require './app/helpers/jobs_helper.rb'
include JobsHelper

namespace :db do
  desc 'archive old jobs'
  task archive_old_jobs: :environment do
    t_id = ENV['ID'].to_i
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        start_job(t_id) if t_id != 0
        JobsHelper.archive_jobs
        finish_job(t_id) if t_id != 0
      rescue => e
        finish_job_with_error(t_id) if t_id != 0
        raise ActiveRecord::Rollback
      end
    end
  end
end
