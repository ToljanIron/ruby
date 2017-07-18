class DropTableFriendship < ActiveRecord::Migration[4.2]
  def change
    drop_table :friendships
  end
end
