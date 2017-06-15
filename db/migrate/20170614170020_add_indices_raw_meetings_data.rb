class AddIndicesRawMeetingsData < ActiveRecord::Migration
  def change
    add_index :raw_meetings_data, [:company_id, :external_meeting_id], name:"index_raw_meetings_data_on_company_id_external_meeting_id", unique: true
    add_index :raw_meetings_data, [:company_id, :subject, :start_time], name:"index_raw_meetings_data_on_company_id_subject_start_time", unique: true
  end
end
