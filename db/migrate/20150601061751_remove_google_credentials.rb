class RemoveGoogleCredentials < ActiveRecord::Migration
  def change
    drop_table :google_credentials if table_exists?(:google_credentials)
  end
end
