class CreateLogfiles < ActiveRecord::Migration[5.1]
  def up
    create_table :logfiles, force: :cascade do |t|
      t.integer :company_id, null: false
      t.string :file_name, null: false
      t.integer :file_type, null: false, default: 1
      t.integer :state, null: false, default: 0
      t.string :error_message
      t.timestamps
    end

    add_index :logfiles, [:company_id, :file_name], name: 'index_logfiles_main', unique: true
    add_index :logfiles, [:company_id, :state], name: 'index_logfiles_state'
  end

  def down
    drop_table :logfiles
  end
end
