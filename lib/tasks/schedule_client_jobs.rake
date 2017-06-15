require './app/helpers/jobs_helper.rb'
include JobsHelper

namespace :db do
  desc 'schedule jobs'
  task schedule_jobs: :environment do
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    JobsHelper.schedule_new_jobs
  end
end
