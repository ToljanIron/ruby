class AlterOverlaySnapshotData < ActiveRecord::Migration
  def change
    rename_column :overlay_snapshot_data, :from_type_id, :from_type
    rename_column :overlay_snapshot_data, :to_type_id, :to_type
  end
end
