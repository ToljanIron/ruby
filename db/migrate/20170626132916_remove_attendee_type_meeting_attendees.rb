class RemoveAttendeeTypeMeetingAttendees < ActiveRecord::Migration
  def change
  	remove_column :meeting_attendees, :attendee_type if column_exists? :meeting_attendees, :attendee_type
  end
end
