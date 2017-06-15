class DropEmailSnapshotData < ActiveRecord::Migration
  def change
    drop_table :email_snapshot_data
  end
end
