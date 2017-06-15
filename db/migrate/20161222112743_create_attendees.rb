class CreateAttendees < ActiveRecord::Migration
  def change
    create_table :attendees do |t|
      t.integer :meeting_id
      t.integer :participant_id
      t.integer :participant_type
    end
  end
end
