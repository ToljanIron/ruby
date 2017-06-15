class AddOverlayEntityTypeToOverlayEntityGroups < ActiveRecord::Migration
  def change
    add_column :overlay_entity_groups, :overlay_entity_type_id, :integer
    add_column :overlay_entity_groups, :image_url, :string
  end
end
