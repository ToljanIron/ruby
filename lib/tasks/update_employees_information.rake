require './lib/tasks/modules/update_employees_information_helper.rb'
include UpdateEmployeesInformationHelper

namespace :db do
  desc 'update_employees_information'
  task :update_employees_information, [:cid] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    company_id = args[:cid] || -1
    ActiveRecord::Base.transaction do
      begin
        UpdateEmployeesInformationHelper.update_employee(company_id.to_i)
      rescue => e
        error = e.message
        puts "got exception: #{error}"
        puts e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
