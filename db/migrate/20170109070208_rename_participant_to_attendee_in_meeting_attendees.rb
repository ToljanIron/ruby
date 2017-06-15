class RenameParticipantToAttendeeInMeetingAttendees < ActiveRecord::Migration
  def up
    rename_column :meeting_attendees, :participant_id, :attendee_id
    rename_column :meeting_attendees, :participant_type, :attendee_type
  end

  def down
    rename_column :meeting_attendees, :attendee_id, :participant_id 
    rename_column :meeting_attendees, :attendee_type, :participant_type
  end
end