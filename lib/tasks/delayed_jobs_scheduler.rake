require './app/helpers/jobs_helper'
include JobsHelper

namespace :db do
  desc 'delayed_jobs_scheduler'
  task :delayed_jobs_scheduler, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    cid = args[:cid] || -1

    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        JobsHelper.schedule_delayed_jobs
      rescue RuntimeError => e
        msg = "delayed_jobs_scheduler failed with exception: #{e.message[0..1000]}"
        EventLog.log_event(company_id: cid, message: msg)
        puts msg
        puts e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
