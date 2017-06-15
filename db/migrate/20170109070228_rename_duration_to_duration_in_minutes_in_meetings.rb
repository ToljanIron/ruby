class RenameDurationToDurationInMinutesInMeetings < ActiveRecord::Migration
  def up
    rename_column :meetings, :duration, :duration_in_minutes
  end

  def down
    rename_column :meetings, :duration_in_minutes, :duration
  end
end
