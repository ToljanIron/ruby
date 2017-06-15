class AddLastContanctTimestampToApiClient < ActiveRecord::Migration
  def change
    add_column :api_clients, :last_contact, :datetime
  end
end
