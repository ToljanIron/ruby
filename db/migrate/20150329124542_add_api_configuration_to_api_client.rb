class AddApiConfigurationToApiClient < ActiveRecord::Migration[4.2]
  def change
    add_column :api_clients, :api_client_configuration_id, :integer
  end
end
