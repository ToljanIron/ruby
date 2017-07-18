class AddSerialToApiClientConfiguration < ActiveRecord::Migration[4.2]
  def change
    add_column :api_client_configurations, :serial, :string
  end
end
