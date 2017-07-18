class CreateOverlayEntitySnapshotData < ActiveRecord::Migration[4.2]
  def change
    create_table :overlay_entity_snapshot_data do |t|
      t.integer :snapshot_id, null: false
      t.integer :from_type_id, null: false
      t.integer :from_id, null: false
      t.integer :to_id, null: false
      t.integer :to_type_id, null: false
      t.integer :value
      t.timestamps null: false
    end
  end
end