class AddIndexAttendeesToRawMeetingsData < ActiveRecord::Migration[5.1]
  def change
    add_index :raw_meetings_data, [:company_id, :start_time, :attendees, :organizer], name:"index_raw_meetings_data_on_attendees", unique: true
  end
end
