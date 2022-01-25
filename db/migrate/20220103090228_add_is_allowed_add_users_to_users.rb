class AddIsAllowedAddUsersToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_allowed_add_users, :boolean, default: false
  end
end
