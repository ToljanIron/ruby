class DropEmployeeAttributes < ActiveRecord::Migration[4.2]
  def change
    drop_table :employee_attributes
  end
end
