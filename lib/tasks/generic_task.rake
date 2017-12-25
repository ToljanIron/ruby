require 'csv'
require 'zip'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    ii = 0
    sids = [118,132,133,134,135]
    count = NetworkSnapshotData.where(snapshot_id: sids).count
    NetworkSnapshotData.where(snapshot_id: sids).offset(3).limit(3)

    puts "Done"

  end
end
