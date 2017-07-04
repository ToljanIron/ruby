class RenameAttendeeIdToEmployeeIdColumnMeetingAttendees < ActiveRecord::Migration
  def change
  	rename_column :meeting_attendees, :attendee_id, :employee_id if column_exists? :meeting_attendees, :attendee_id
  end
end
