class AddIsVerifiedToEmployees < ActiveRecord::Migration[6.1]
  def change
    add_column :employees, :is_verified, :bool, default: true
  end
end
