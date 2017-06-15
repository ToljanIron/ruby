require './lib/tasks/modules/convert_employee_attribute_to_new_attributes_table_helper.rb'
namespace :db do
  desc 'convert_employee_attribute_to_new_attributes_table'
  task convert_employee_attribute_to_new_attributes_table: :environment do
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        ConvertEmployeeAttributeToNewAttributesTableHelper.convert_employee_attributes
      rescue => e
        error = e.message
        puts "got exception: #{error}"
        puts e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
