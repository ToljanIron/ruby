class CreateArchivedApiClientTasks < ActiveRecord::Migration[4.2]
  def change
    create_table :archived_api_client_tasks do |t|
      t.integer :api_client_task_definition_id
      t.integer :status
      t.string  :params
      t.integer :jobs_queue_id
      t.integer :api_client_id
      t.timestamps null: false
    end
  end
end
