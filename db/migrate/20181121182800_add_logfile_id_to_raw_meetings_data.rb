class AddLogfileIdToRawMeetingsData < ActiveRecord::Migration[5.1]
  def up
    add_column :raw_meetings_data, :logfile_id, :integer, default: nil
  end

  def down
    remove_column :raw_meetings_data, :logfile_id
  end
end
