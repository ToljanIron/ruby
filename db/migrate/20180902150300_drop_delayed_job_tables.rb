class DropDelayedJobTables < ActiveRecord::Migration[5.1]
  def up
    drop_table :jobs
    drop_table :delayed_jobs
    drop_table :job_to_api_client_task_convertors
    drop_table :jobs_archives
    drop_table :jobs_queues
    drop_table :reoccurrences
    drop_table :scheduled_api_client_tasks
  end

  def down
  end
end
