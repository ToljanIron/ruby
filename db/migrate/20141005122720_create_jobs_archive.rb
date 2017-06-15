class CreateJobsArchive < ActiveRecord::Migration
  def change
    create_table :jobs_archives do |t|
      t.integer :job_id, null: false
      t.integer :status, null: false
      t.boolean :order_type, null: false
      t.timestamps
    end
  end
end
