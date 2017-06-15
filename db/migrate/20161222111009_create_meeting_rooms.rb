class CreateMeetingRooms < ActiveRecord::Migration
  def change
    create_table :meeting_rooms do |t|
      t.string :name
      t.integer :office_id
    end
  end
end
