class MeetingAttendeesAddIndices < ActiveRecord::Migration
  def change
    add_index :meeting_attendees, [:meeting_id], name:"index_attendees_on_meeting_id"
    add_index :meeting_attendees, [:attendee_id], name:"index_attendees_on_attendee_id"
    add_index :meeting_attendees, [:meeting_id,:attendee_id], name:"index_attendees_on_meeting_id_attendee_id", unique: true
  end
end
