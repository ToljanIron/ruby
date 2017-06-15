class AddSerialToApiClientConfiguration < ActiveRecord::Migration
  def change
    add_column :api_client_configurations, :serial, :string
  end
end
