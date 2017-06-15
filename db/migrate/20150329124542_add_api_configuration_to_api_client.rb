class AddApiConfigurationToApiClient < ActiveRecord::Migration
  def change
    add_column :api_clients, :api_client_configuration_id, :integer
  end
end
