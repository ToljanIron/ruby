class RenameAttendeesToMeetingAttendees < ActiveRecord::Migration
  def change
    rename_table :attendees, :meeting_attendees
  end
end
