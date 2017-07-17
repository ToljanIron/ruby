class AddResponseToMeetingAttendees < ActiveRecord::Migration[4.2]
  def change
  	add_column :meeting_attendees, :response, :integer, default: 0 if !column_exists? :meeting_attendees, :response
  end
end
