require './app/helpers/jobs_helper.rb'
include JobsHelper

namespace :db do
  desc 'test jobs task'
  task test_job_task: :environment do
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    if Job.find(ENV['ID']).job_status == JobsQueue::PENDING
      start_job(ENV['ID'])
      sleep(2.seconds)
      finish_job(ENV['ID'])
    end
  end
end
