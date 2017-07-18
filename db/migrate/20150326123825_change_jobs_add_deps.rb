class ChangeJobsAddDeps < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :job_id, :integer
    add_column :jobs, :dont_schedule_if_working_job_id, :integer
  end
end
