namespace :db do
  require './lib/tasks/modules/create_alerts_task_helper.rb'
  require './app/helpers/cds_util_helper.rb'
  include CreateAlertsTaskHelper
  include CdsUtilHelper

  desc 'create_alerts'
  task :create_alerts, [:cid, :sid] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    puts "create_alerts job started"
    EventLog.log_event(message: 'create_alerts started')

    CdsUtilHelper.cache_delete_all
    cid = args[:cid] || -1
    sid = args[:sid] || -1


    begin
      [200,201,203,204,205,206,207,208,303].each do |aid|
        puts "Working on algorithm: #{aid}"
        CreateAlertsTaskHelper.create_alerts(cid, sid, aid)
      end
      EventLog.log_event(message: 'create_alerts job finished')
    rescue => e
      puts "Job failed with error: #{e.message}"
      puts e.backtrace
      EventLog.log_event(message: 'create_alerts job failed')
    end

  end
end
