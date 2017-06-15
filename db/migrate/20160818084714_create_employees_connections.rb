class CreateEmployeesConnections < ActiveRecord::Migration
  def change
    create_table :employees_connections, id: false do |t|
      t.integer :employee_id, null: false
      t.integer :connection_id, null: false
    end
  end
end
