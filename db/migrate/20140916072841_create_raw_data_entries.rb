class CreateRawDataEntries < ActiveRecord::Migration
  def change
    create_table :raw_data_entries do |t|
      t.integer   :company_id,       null: false
      t.string    :msg_id,           null: false
      t.string    :reply_to_msg_id,  default: ''
      t.string    :from,             null: false
      t.string    :to,               array: true, default: []
      t.string    :cc,               array: true, default: []
      t.string    :bcc,              array: true, default: []
      t.timestamp :date,             null: false
      t.boolean   :fwd,              default: false
      t.boolean   :processed,        default: false
      t.integer   :priority

      t.timestamps
    end
    add_index :raw_data_entries, [:processed], name: 'index_raw_data_on_processed'
    add_index :raw_data_entries, [:date], name: 'index_raw_data_on_date'
  end
end
