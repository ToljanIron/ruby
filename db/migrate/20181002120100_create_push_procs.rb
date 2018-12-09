class CreatePushProcs < ActiveRecord::Migration[5.1]
  def up
    if !ActiveRecord::Base.connection.table_exists? 'push_procs'
      create_table :push_procs, force: :cascade do |t|
        t.integer :company_id, null: false
        t.integer :state, null: false, default: 0
        t.integer :num_files, default: 0
        t.integer :num_files_processed, default: 0
        t.integer :num_snapshots, default: 0
        t.integer :num_snapshots_created, default: 0
        t.integer :num_snapshots_processed, default: 0
        t.string :error_message
        t.timestamps
      end
    end
  end

  def down
    drop_table :push_procs
  end
end
