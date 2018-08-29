class ChangeIndexRawDataEntriesOnMsgId < ActiveRecord::Migration[5.1]
  def change
    remove_index :raw_data_entries, name: 'index_raw_data_entries_on_msg_id'
    add_index :raw_data_entries, :msg_id, name: 'index_raw_data_entries_on_msg_id', unique: true
  end
end
