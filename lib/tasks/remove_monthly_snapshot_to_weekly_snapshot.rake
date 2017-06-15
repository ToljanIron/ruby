require './lib/tasks/modules/create_snapshot_helper.rb'
include CreateSnapshotHelper

namespace :db do
  desc 'remove_monthly_snapshot_to_weekly_snapshot'
  task :remove_monthly_snapshot_to_weekly_snapshot, [:cid, :sid] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    error = nil
    ActiveRecord::Base.transaction do
      begin
        cid = args[:cid] || ENV['COMPANY_ID'] || (fail 'No company ID given (cid)')
        sid = args[:sid].to_i || -1
        CreateSnapshotHelper::convert_monthly_snapshot_to_weekly_snapshot(cid, sid)
      rescue ActiveRecord::Rollback
        puts "remove_monthly_snapshot_to_weekly_snapshot ERROR: Failed with error: #{error}"
      end
    end
  end
end
