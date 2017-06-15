class AddColorForUiLevels < ActiveRecord::Migration
  def change
    add_column :ui_level_configurations, :color_id, :string
  end
end
