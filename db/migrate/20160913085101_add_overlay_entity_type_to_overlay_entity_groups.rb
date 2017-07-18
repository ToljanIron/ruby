class AddOverlayEntityTypeToOverlayEntityGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :overlay_entity_groups, :overlay_entity_type_id, :integer
    add_column :overlay_entity_groups, :image_url, :string
  end
end
