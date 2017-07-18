class DropEmailSnapshotData < ActiveRecord::Migration[4.2]
  def change
    drop_table :email_snapshot_data
  end
end
