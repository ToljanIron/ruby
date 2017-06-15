require './lib/tasks/modules/convert_employee_attribute_to_new_attributes_table_helper.rb'

class DropEmployeeAttributes < ActiveRecord::Migration
  def change
    ConvertEmployeeAttributeToNewAttributesTableHelper.convert_employee_attributes
    drop_table :employee_attributes
  end
end
