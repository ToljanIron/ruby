class AddIdNumberToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :id_number, :string
  end
end
