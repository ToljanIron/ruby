require 'csv'
require 'zip'
require 'json'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    CSV.foreach("./lycored-managers.csv") do |l|

      efn = l[0].try(:strip)
      eln = l[1].try(:strip)
      man = l[2].nil? ? nil : l[2].split(',')
      mfn = man[1].try(:strip) if !man.nil?
      mln = man[0].try(:strip) if !man.nil?

      #puts "first name: #{efn}, last name: #{eln}, manager first name: #{mfn}, manager last name: #{mln}"

      emp = Employee.find_by(first_name: efn, last_name: eln)
      if emp.nil?
        puts "EMPLOYEE NOT FOUND - #{l}"
        next
      end

      man = Employee.find_by(first_name: mfn, last_name: mln)
      if man.nil?
        puts "MANAGER NOT FOUND - #{l}"
        next
      end

      EmployeeManagementRelation.create!(manager_id: man.id, employee_id: emp.id, relation_type: 0)
    end
  end
end

