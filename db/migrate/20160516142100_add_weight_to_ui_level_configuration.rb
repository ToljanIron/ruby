class AddWeightToUiLevelConfiguration < ActiveRecord::Migration
  def up
    add_column :ui_level_configurations, :weight, :float, default: nil
  end

  def down
    remove_column :ui_level_configurations, :weight
  end
end
