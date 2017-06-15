require 'csv'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    cid   = args[:cid]

    puts ">>>#{Dir.pwd}<<<"
    puts "Starting"

    puts "Reading CSV"
    pairs = CSV.read('./employee-group.csv')

    puts "Prepering hash"
    groups_hash = {}
    pairs.each do |p|
      groups_hash[p[0]] = p[1]
    end

    puts "Update employees"
    emps = Employee.where(company_id: cid)
    emps.each do |e|
      extid = e.external_id
      group = groups_hash[extid]
      gid = Group.find_by(name: group).try(:id)
      puts "Updating #{extid} to group: #{group}"
      Employee.find_by(external_id: extid).update(group_id: gid)
    end

    puts "Done"

  end
end
