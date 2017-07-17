class AddOrganizerMeetingsSnapshotData < ActiveRecord::Migration[4.2]
  def change
  	add_column :meetings_snapshot_data, :organizer_id, :integer unless column_exists? :meetings_snapshot_data, :organizer_id
  end
end