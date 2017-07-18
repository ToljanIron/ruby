class AddBackgroundColorToGauges < ActiveRecord::Migration[4.2]
  def change
  add_column :gauge_configurations, :background_color, :string
  end
end
