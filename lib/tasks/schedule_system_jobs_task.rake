require './app/helpers/jobs_helper.rb'
include JobsHelper

namespace :db do
  desc 'schedule jobs task'
  task schedule_system_jobs_task: :environment do
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    JobsHelper.schedule_new_system_jobs
  end
end
