class CreateAttendees < ActiveRecord::Migration[4.2]
  def change
    create_table :attendees do |t|
      t.integer :meeting_id
      t.integer :participant_id
      t.integer :participant_type
    end
  end
end
