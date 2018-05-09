class AddIndexToEmployeesConnections < ActiveRecord::Migration[4.2]
  def change
    add_index :employees_connections, :employee_id
  end
end
