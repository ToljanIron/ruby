class AddDescriptionAndObservationToUiLevels < ActiveRecord::Migration[4.2]
  def change
    add_column :ui_level_configurations, :description, :string
    add_column :ui_level_configurations, :observation, :string

  end
end
