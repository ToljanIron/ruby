class CreateJobStages < ActiveRecord::Migration[5.1]
  def up
    create_table :job_stages do |t|

      # This is how this stage identifies what it has to perform. eg: a stage
      # for retreiving an employee's emails from office365 the value of this
      # field can be the user_id of this employee in the Office365 API.
      t.string  :domain_id,   null: false

      t.integer :job_id,  null: false
      t.integer :company_id,  null: false

      # ready, running, done, error
      t.integer  :status,  null: false, default: 0

      # A free field describing this stage
      t.string  :stage_type,   null: false

      # Stage execution order. Can be emtpy
      t.integer :stage_order

      # A textual representation of the work to be done. For example it can
      # be an array of IDs: [id1, id2, .. ]
      t.string :value

      # A summary of this stage or an error message in case it failed
      t.string :res

      # Date of move into running state
      t.datetime  :run_start_at

      # Date of move out of running state
      t.datetime  :run_end_at

      t.timestamps
    end

    add_index :job_stages, [:company_id, :job_id, :domain_id],  name: 'index_job_stages_uniquely', unique: true
  end

  def down
    drop_table :job_stages
  end
end
