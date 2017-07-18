class ChangeApiClientConfigurations < ActiveRecord::Migration[4.2]
  def change
    remove_column :api_client_configurations, :api_client_id
    add_column    :api_client_configurations, :active, :boolean
  end
end

