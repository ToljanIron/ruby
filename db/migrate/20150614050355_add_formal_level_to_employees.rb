class AddFormalLevelToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :formal_level, :integer unless column_exists? :employees, :formal_level
  end
end
