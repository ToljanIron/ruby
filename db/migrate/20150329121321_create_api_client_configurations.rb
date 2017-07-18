class CreateApiClientConfigurations < ActiveRecord::Migration[4.2]
  def change
    create_table :api_client_configurations do |t|
      t.integer :api_client_id
      t.string  :active_time_start
      t.string  :active_time_end
      t.integer :disk_space_limit_in_mb
      t.integer :wakeup_interval_in_seconds
      t.timestamps null: false
    end
  end
end
