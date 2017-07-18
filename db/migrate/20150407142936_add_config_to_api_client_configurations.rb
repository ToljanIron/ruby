class AddConfigToApiClientConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :api_client_configurations, :duration_of_old_logs_by_months, :integer
    add_column :api_client_configurations, :log_max_size_in_mb, :integer
  end
end
