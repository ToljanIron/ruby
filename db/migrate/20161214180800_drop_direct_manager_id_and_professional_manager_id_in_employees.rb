class DropDirectManagerIdAndProfessionalManagerIdInEmployees < ActiveRecord::Migration
  def change
    remove_column :employees, :direct_manager_id
    remove_column :employees, :professional_manager_id
  end
end
