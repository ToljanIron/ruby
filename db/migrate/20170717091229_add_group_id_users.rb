class AddGroupIdUsers < ActiveRecord::Migration[5.1]
  def change
  	add_column :users, :group_id, :integer unless column_exists? :users, :group_id
  end
end