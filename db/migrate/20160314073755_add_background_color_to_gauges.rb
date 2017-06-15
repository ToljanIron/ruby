class AddBackgroundColorToGauges < ActiveRecord::Migration
  def change
  add_column :gauge_configurations, :background_color, :string
  end
end
