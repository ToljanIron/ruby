class AddDirectManagerIdAndProfessionalManagerIdToEmployees < ActiveRecord::Migration[4.2]
  def change
    add_column :employees, :direct_manager_id, :integer
    add_column :employees, :professional_manager_id, :integer
  end
end
