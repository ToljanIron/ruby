class RenameMeetingsTable < ActiveRecord::Migration
  def change
  	rename_table :meetings, :meetings_snapshot_data if !ActiveRecord::Base.connection.table_exists? 'meetings_snapshot_data'
  end
end
