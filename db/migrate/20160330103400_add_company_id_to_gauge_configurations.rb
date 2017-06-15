class AddCompanyIdToGaugeConfigurations < ActiveRecord::Migration
  def up
    add_column :gauge_configurations, :company_id, :integer, default: -1
  end

  def down
    remove_column :gauge_configurations, :company_id
  end
end
