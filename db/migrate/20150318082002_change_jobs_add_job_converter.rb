class ChangeJobsAddJobConverter < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :job_to_api_client_task_convertor_id, :integer
  end
end
