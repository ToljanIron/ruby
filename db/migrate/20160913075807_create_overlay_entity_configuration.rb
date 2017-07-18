class CreateOverlayEntityConfiguration < ActiveRecord::Migration[4.2]
  def change
    create_table :overlay_entity_configurations do |t|
      t.integer :company_id, null: false
      t.integer :overlay_entity_type_id, null: false
      t.boolean :active, default: true
      t.timestamps null: false
    end
  end
end
