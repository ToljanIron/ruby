class AddMeetingTypeMeetingsSnapshotDataTable < ActiveRecord::Migration[4.2]
  def up
  	add_column :meetings_snapshot_data, :meeting_type, :integer, default: 0 unless column_exists? :meetings_snapshot_data, :meeting_type
  end

  def down
    remove_column :meetings_snapshot_data, :meeting_type
  end
end
