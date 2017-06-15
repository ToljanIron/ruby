class AddDescriptionAndObservationToUiLevels < ActiveRecord::Migration
  def change
    add_column :ui_level_configurations, :description, :string
    add_column :ui_level_configurations, :observation, :string

  end
end
