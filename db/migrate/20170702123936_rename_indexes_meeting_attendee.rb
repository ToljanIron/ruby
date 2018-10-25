class RenameIndexesMeetingAttendee < ActiveRecord::Migration[4.2]
  # Migration for renaming indices after column rename,
  # so indices names will be consistent
  def change
  	rename_index  :meeting_attendees, "index_attendees_on_attendee_id", "index_meeting_attendees_on_employee_id" if ActiveRecord::Base.connection.index_name_exists?(:meeting_attendees, "index_attendees_on_attendee_id")
  	rename_index  :meeting_attendees, "index_attendees_on_meeting_id", "index_meeting_attendees_on_meeting_id" if ActiveRecord::Base.connection.index_name_exists?(:meeting_attendees, "index_attendees_on_meeting_id")
  	rename_index  :meeting_attendees, "index_attendees_on_meeting_id_attendee_id", "index_meeting_attendees_on_meeting_id_employee_id" if ActiveRecord::Base.connection.index_name_exists?(:meeting_attendees, "index_attendees_on_meeting_id_attendee_id")
  end
end
