class RenameOverlayEntitySnapshotData < ActiveRecord::Migration[4.2]
  def change
    rename_table :overlay_entity_snapshot_data, :overlay_snapshot_data
  end
end
