class AddPermissibleGroupToUsers < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :permissible_group, :string, default: nil
    remove_column :users, :group_id
  end

  def down
    remove_column :users, :permissible_group
    add_column :users, :group_id, :integer, default: nil
  end
end
