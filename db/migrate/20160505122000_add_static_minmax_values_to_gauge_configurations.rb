class AddStaticMinmaxValuesToGaugeConfigurations < ActiveRecord::Migration
  def self.up
    add_column :gauge_configurations, :static_minimum, :float
    add_column :gauge_configurations, :static_maximum, :float
  end

  def self.down
    remove_column :gauge_configurations, :static_minimum
    remove_column :gauge_configurations, :static_maximum
  end
end
