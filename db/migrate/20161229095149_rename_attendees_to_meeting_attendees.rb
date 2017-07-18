class RenameAttendeesToMeetingAttendees < ActiveRecord::Migration[4.2]
  def change
    rename_table :attendees, :meeting_attendees
  end
end
