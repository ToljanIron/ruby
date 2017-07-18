class AddQuestionnaireFieldsToEmployees < ActiveRecord::Migration[4.2]
  def up
    add_column :employees, :active, :boolean, default: true
    add_column :employees, :phone_number, :string
  end

  def down
    remove_column :employees, :active
    remove_column :employees, :phone_number
  end
end
