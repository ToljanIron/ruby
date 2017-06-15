class RenameOverlayEntitySnapshotData < ActiveRecord::Migration
  def change
    rename_table :overlay_entity_snapshot_data, :overlay_snapshot_data
  end
end
