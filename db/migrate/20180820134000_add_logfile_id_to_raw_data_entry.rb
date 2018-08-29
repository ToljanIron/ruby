class AddLogfileIdToRawDataEntry < ActiveRecord::Migration[5.1]
  def up
    add_column :raw_data_entries, :logfile_id, :integer, default: nil
  end

  def down
    remove_column :raw_data_entries, :logfile_id
  end
end
