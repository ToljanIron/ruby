class AddUseEmployeeConnectionsToQuestionnaire < ActiveRecord::Migration[5.1]
  def up
    add_column :questionnaires, :use_employee_connections, :boolean, default: false
  end

  def down
    remove_column :questionnaires, :use_employee_connections
  end
end
