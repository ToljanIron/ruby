class AddMeetingTypeMeetingsSnapshotDataTable < ActiveRecord::Migration[4.2]
  def change
  	add_column :meetings_snapshot_data, :meeting_type, :integer unless column_exists? :meetings_snapshot_data, :meeting_type
  end
end
