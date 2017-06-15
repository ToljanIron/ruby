class CreateRawMeetingsData < ActiveRecord::Migration
  def change
    create_table :raw_meetings_data do |t|
      t.string :subject
      t.string :attendees
      t.string :duration_in_minutes
      t.string :location
      t.string :external_meeting_id
      t.integer :company_id, null: false
      t.timestamp :start_time, null: false
      t.boolean :processed, default: false
      t.timestamps null: false
    end
  end
end
