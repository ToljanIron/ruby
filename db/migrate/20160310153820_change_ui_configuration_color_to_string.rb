class ChangeUiConfigurationColorToString < ActiveRecord::Migration
  def change
    remove_column :ui_level_configurations, :color_id
    add_column :ui_level_configurations, :color, :string
  end
end
