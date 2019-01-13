class ChangeAttendeesInRawMeetingsData < ActiveRecord::Migration[5.1]
  def change
    remove_column :raw_meetings_data, :attendees
  	add_column :raw_meetings_data, :attendees, :string, array: true, default: []
  end
end
