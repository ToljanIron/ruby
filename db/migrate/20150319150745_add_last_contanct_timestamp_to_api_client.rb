class AddLastContanctTimestampToApiClient < ActiveRecord::Migration[4.2]
  def change
    add_column :api_clients, :last_contact, :datetime
  end
end
