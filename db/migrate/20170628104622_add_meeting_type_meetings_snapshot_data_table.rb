class AddMeetingTypeMeetingsSnapshotDataTable < ActiveRecord::Migration
  def change
  	add_column :meetings_snapshot_data, :meeting_type, :integer unless column_exists? :meetings_snapshot_data, :meeting_type
  end
end
