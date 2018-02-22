require 'csv'
require 'zip'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    nsds = NetworkSnapshotData.where(snapshot_id: [94,145])
    nsds.each do |nsd|
      next if rand(1..10) > 3
      puts "Adding some emails"
      (1..rand(1..5)).each do
        NetworkSnapshotData.create!(
          snapshot_id: nsd[:snapshot_id],
          network_id: nsd[:network_id],
          company_id: 11,
          from_employee_id: nsd[:from_employee_id],
          to_employee_id: nsd[:to_employee_id],
          value: 1,
          message_id: SecureRandom.base58(24),
          from_type: 2,
          to_type: 1
        )
      end
    end

    puts "Done"

  end
end
