class AddDirectManagerIdAndProfessionalManagerIdToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :direct_manager_id, :integer
    add_column :employees, :professional_manager_id, :integer
  end
end
