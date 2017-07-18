class DropDirectManagerIdAndProfessionalManagerIdInEmployees < ActiveRecord::Migration[4.2]
  def change
    remove_column :employees, :direct_manager_id
    remove_column :employees, :professional_manager_id
  end
end
