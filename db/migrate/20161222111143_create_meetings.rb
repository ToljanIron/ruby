class CreateMeetings < ActiveRecord::Migration
  def change
    create_table :meetings do |t|
      t.string :subject
      t.integer :meeting_room_id
      t.integer :snapshot_id
      t.integer :duration
      t.timestamp :start_time
      t.integer :company_id
      t.string :meeting_uniq_id
    end
  end
end
