class RenameDurationToDurationInMinutesInMeetings < ActiveRecord::Migration[4.2]
  def up
    rename_column :meetings, :duration, :duration_in_minutes
  end

  def down
    rename_column :meetings, :duration_in_minutes, :duration
  end
end
