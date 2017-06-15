class CreateJobToApiClientTaskConvertors < ActiveRecord::Migration
  def change
    create_table :job_to_api_client_task_convertors do |t|
      t.integer :job_id
      t.string  :algorithm_name
      t.string  :name
      t.timestamps null: false
    end
  end
end
