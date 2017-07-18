class CreateJobsQueue < ActiveRecord::Migration[4.2]
  def change
    create_table :jobs_queues do |t|
      t.integer :job_id, null: false
      t.integer :status, null: false, default: 0
      t.boolean :order_type, null: false
      t.boolean :running, null: false, defualt: false
      t.timestamps
    end
  end
end
