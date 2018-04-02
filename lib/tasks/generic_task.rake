require 'csv'
require 'zip'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    emps = Employee.where(snapshot_id: 145).select(:id, :group_id).order(:group_id, :id).pluck(:group_id, :id)
    group_managers = {}

    prevgid = 0
    mid = -1
    ii = 0

    puts "Relations with employees"
    puts "==============================="
    emps.each do |e|
      eid = e[1]
      gid = e[0]

      if gid != prevgid
        mid = eid
        prevgid = gid
        group_managers[gid] = mid
        next
      end

      ii += 1
      puts "[#{ii}] - group: #{gid}, mid: #{mid}, eid: #{eid}"
      EmployeeManagementRelation.create!(
        manager_id: mid,
        employee_id: eid,
        relation_type: :recursive
      )
    end

    puts "Relations with managers"
    puts "==============================="
    group_managers.keys.each do |gid|
      g = Group.find(gid)
      pgid = g.parent_group_id
      next if pgid.nil?
      pgid_mid = group_managers[pgid]
      g_mid = group_managers[gid]

      ii += 1
      puts "[#{ii}] - gid: #{gid}, pgid: #{pgid}, pgid_mid: #{pgid_mid}, g_mid: #{g_mid}"
      EmployeeManagementRelation.create!(
        manager_id: pgid_mid,
        employee_id: g_mid,
        relation_type: :recursive
      )
    end

    puts "Done"

  end
end
