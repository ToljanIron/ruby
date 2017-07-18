class AddIdNumberToEmployees < ActiveRecord::Migration[4.2]
  def change
    add_column :employees, :id_number, :string
  end
end
