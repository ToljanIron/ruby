class AddIndexToRawMettingsData < ActiveRecord::Migration[4.2]
  def change
    add_index :raw_meetings_data, [:company_id, :external_meeting_id], name: 'index_raw_meetings_data_on_external_meeting_id', unique: true
    add_index :raw_meetings_data, [:company_id, :start_time, :subject, :attendees], name: 'index_raw_meetings_data_on_start_time_and_subject_and_attendees', unique: true 
  end
end
