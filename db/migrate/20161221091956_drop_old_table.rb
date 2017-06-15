class DropOldTable < ActiveRecord::Migration
  def up
    drop_table :advices_snapshots if (table_exists? :advices_snapshots)
    drop_table :trusts_snapshots if (table_exists? :trusts_snapshots)
    drop_table :friendships_snapshots if (table_exists? :friendships_snapshots)
    drop_table :word_clouds if (table_exists? :word_clouds)
  end
  def down
  end
end
