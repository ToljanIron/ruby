class ChangeRoleInUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :role
    add_column :users, :role, :integer
  end
end
