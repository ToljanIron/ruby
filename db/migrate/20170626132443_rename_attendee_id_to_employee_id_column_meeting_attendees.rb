class RenameAttendeeIdToEmployeeIdColumnMeetingAttendees < ActiveRecord::Migration[4.2]
  def change
  	rename_column :meeting_attendees, :attendee_id, :employee_id if column_exists? :meeting_attendees, :attendee_id
  end
end
