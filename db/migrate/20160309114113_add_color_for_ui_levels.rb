class AddColorForUiLevels < ActiveRecord::Migration[4.2]
  def change
    add_column :ui_level_configurations, :color_id, :string
  end
end
