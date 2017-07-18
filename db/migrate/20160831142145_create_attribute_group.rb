class CreateAttributeGroup < ActiveRecord::Migration[4.2]
  def change
    create_table :overlay_entity_groups do |t|
      t.integer :company_id, null: false
      t.string :name
      t.timestamps null: false
    end
  end
end
