class CreateGoogleCredentials < ActiveRecord::Migration[4.2]
  def change
    create_table :google_credentials do |t|
      t.integer :company_id
      t.string :refresh_token
      t.string :access_token

      t.timestamps null: false
    end
  end
end
