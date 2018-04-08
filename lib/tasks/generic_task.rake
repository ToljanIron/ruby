require 'csv'
require 'zip'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    emps = Employee.where(snapshot_id: 118).select(:id, :snapshot_id, :external_id)

    h_extid = {}
    emps.each do |e|
      h_extid[e[:external_id]] = e[:id]
    end


    ff = File.open("./insert.sql","w")
    ii = 0
    puts "start going over csv"
    CSV.foreach('bog-management2.csv') do |r|
      ii += 1
      puts "#{ii} out of 4800" if (ii % 100 == 0)
      mid = h_extid[r[0]]
      eid = h_extid[r[1]]

      next if (mid.nil? || eid.nil?)
      str = "(#{mid},#{eid},2,current_timestamp,current_timestamp),\n"
      ff.write(str)
    end
    ff.close

    #puts "[#{ii}] - group: #{gid}, mid: #{mid}, eid: #{eid}"
    #EmployeeManagementRelation.create!(
      #manager_id: mid,
      #employee_id: eid,
      #relation_type: :recursive
    #)

    puts "Done"

  end
end
