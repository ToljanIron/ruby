
namespace :db do
  desc 'clean_jobs'
  task :clean_jobs, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    RawDataEntry.delete_all
    RawMeetingsData.delete_all
    Job.delete_all
    JobStage.delete_all
    EventLog.delete_all
    Logfile.delete_all
    Delayed::Job.delete_all

    MeetingsSnapshotData.delete_all
    MeetingAttendee.delete_all
    NetworkSnapshotData.delete_all
    CdsMetricScore.delete_all

    Snapshot.where.not(id: 1).delete_all
    Employee.delete_all
    Group.delete_all

    Company.last.update!(setup_state: 0)
    puts "Done"
  end
end
