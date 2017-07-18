class RemoveGoogleCredentials < ActiveRecord::Migration[4.2]
  def change
    drop_table :google_credentials if table_exists?(:google_credentials)
  end
end
