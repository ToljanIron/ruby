class CreateApiClient < ActiveRecord::Migration
  def change
    create_table :api_clients do |t|
      t.string :token, null: false
      t.string :client_name
      t.datetime :expires_on, null: false

      t.timestamps
    end
    add_index :api_clients, :token, unique: true
  end
end
