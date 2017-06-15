class AddGaugeConfiguration < ActiveRecord::Migration
  def change
    create_table :gauge_configurations do |t|
      t.integer  :minimum_value, null: false
      t.integer  :maximum_value, null: false
      t.integer  :minimum_area, null: false
      t.integer  :maximum_area, null: true
    end
  end
end
