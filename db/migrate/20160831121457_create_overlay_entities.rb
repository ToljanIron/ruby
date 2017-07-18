class CreateOverlayEntities < ActiveRecord::Migration[4.2]
  def change
    create_table :overlay_entities do |t|
      t.integer :company_id, null: false
      t.integer :overlay_entity_type_id, null: false
      t.integer :overlay_entity_group_id
      t.string :name
      t.boolean :active, default: true
      t.timestamps null: false
    end
  end
end
