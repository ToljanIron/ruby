require './lib/tasks/modules/create_snapshot_helper.rb'
require './app/helpers/jobs_helper.rb'
include JobsHelper
include CreateSnapshotHelper
namespace :db do
  desc 'create_snapshot_for_e2e'
  task :create_snapshot_for_e2e, [:cid, :type] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ERROR = 1
    t_id = ENV['ID'].to_i
    status = nil
    EventLog.log_event(job_id: t_id, message: 'create_snapshot_for_e2e statred')
    start_job(t_id) if t_id != 0
    cid   = args[:cid]  || ENV['COMPANY_ID'] || (fail 'No company ID given (cid)')
    stype = args[:type] || ENV['STYPE']      || (fail 'No snapshot type given, 0-weely, 1-monthly, 2-yearly')
    date = nil
    s = Snapshot.last
    if s
      date = (Snapshot.last.created_at + 1.month).strftime('%Y-%m-%d')
    else
      date = Time.now.strftime('%Y-%m-%d')
    end
    puts "Running with CID=#{cid}, date=#{date}, stype=#{stype}"
    ActiveRecord::Base.transaction do
      begin
        puts "Running create_company_snapshot()"
        CreateSnapshotHelper::create_company_snapshot_by_weeks(cid.to_i, date)
        puts "Done create_company_snapshot()"
        finish_job(t_id) if t_id != 0
        EventLog.log_event(job_id: t_id, message: 'create_snapshot_for_e2e ended')
      rescue => e
        puts e.message
        puts e.backtrace.join("\n")
        finish_job_with_error(t_id) if t_id != 0
        status = ERROR
        raise ActiveRecord::Rollback
      end
    end
    EventLog.log_event(job_id: t_id, message: 'create_snapshot_for_e2e error') if status == ERROR
  end
end
