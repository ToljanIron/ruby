class AddAgeGroupAndSeniorityToEmployees < ActiveRecord::Migration[4.2]
  def change
    add_column :employees, :age_group_id, :integer
    add_column :employees, :seniority_id, :integer
  end
end
