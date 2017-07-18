class AlterOverlaySnapshotData < ActiveRecord::Migration[4.2]
  def change
    rename_column :overlay_snapshot_data, :from_type_id, :from_type
    rename_column :overlay_snapshot_data, :to_type_id, :to_type
  end
end
