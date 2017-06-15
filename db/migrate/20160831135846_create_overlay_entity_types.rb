class CreateOverlayEntityTypes < ActiveRecord::Migration
  def change
    create_table :overlay_entity_types do |t|
      t.integer :overlay_entity_type
      t.string :name
      t.string :image_url
      t.integer :network_id_1
      t.integer :network_id_2
      t.integer :network_id_3
      t.integer :color_id
      t.timestamps null: false
    end
  end
end
