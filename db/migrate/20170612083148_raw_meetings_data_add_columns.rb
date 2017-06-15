class RawMeetingsDataAddColumns < ActiveRecord::Migration
  def change
    add_column :raw_meetings_data, :organizer, :string
    add_column :raw_meetings_data, :meeting_type, :integer
    add_column :raw_meetings_data, :is_cancelled, :boolean
    add_column :raw_meetings_data, :show_as, :integer
    add_column :raw_meetings_data, :importance, :integer
    add_column :raw_meetings_data, :has_attachments, :boolean
    add_column :raw_meetings_data, :is_reminder_on, :boolean
  end
end
