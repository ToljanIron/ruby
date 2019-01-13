class CreateJobs < ActiveRecord::Migration[5.1]
  def up
    create_table :jobs do |t|
      t.integer :company_id,  null: false

      # This is how the job is recoginzed by the owning module, eg: o365_collection_20180110
      t.string  :domain_id,   null: false

      # o365_collector, exchange_collector, etc ...
      t.string  :module_name, null: false

      # ready, in_progress, wait_for_retry, done, error
      t.integer  :status,  null: false, default: 0

      # A free field describing the type of the job: collection, historical run, precalculate, etc ...
      t.string  :job_type,   null: false

      # Max number of retries
      t.integer :max_number_of_retries, null: false, default: 3

      # How many retries were already run
      t.integer :number_of_retries, null: false, default: 0

      # If the job failed, this field gives an error message
      t.string :error_message

      # This field, which is not mandatory can refference any entity, when relevant.
      # For example, can reference a snapshot or a questionnaire
      t.integer :ref_id

      # Date of move into in_progress_state
      t.datetime  :run_start_at

      # Date of move out of in_progress_state
      t.datetime  :run_end_at

      t.timestamps
    end
    add_index :jobs, [:company_id, :module_name, :domain_id],  name: 'index_jobs_uniquely', unique: true
  end

  def down
    drop_table :jobs
  end
end
