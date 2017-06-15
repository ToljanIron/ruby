class AddUiLevelConfiguration < ActiveRecord::Migration
  def change
    create_table :ui_level_configurations do |t|
      t.integer  :company_id, null: false
      t.integer  :level, null: false
      t.integer  :parent_id
      t.integer  :display_order
      t.string   :name
      t.integer  :company_metric_id, null: true
      t.integer  :gauge_id, null: true
    end
  end
end
