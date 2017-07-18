class RawMeetingsDataAddColumns < ActiveRecord::Migration[4.2]
  def change
    add_column :raw_meetings_data, :organizer, :string unless column_exists? :raw_meetings_data, :organizer
    add_column :raw_meetings_data, :meeting_type, :integer unless column_exists? :raw_meetings_data, :meeting_type
    add_column :raw_meetings_data, :is_cancelled, :boolean unless column_exists? :raw_meetings_data, :is_cancelled
    add_column :raw_meetings_data, :show_as, :integer unless column_exists? :raw_meetings_data, :show_as
    add_column :raw_meetings_data, :importance, :integer unless column_exists? :raw_meetings_data, :importance
    add_column :raw_meetings_data, :has_attachments, :boolean unless column_exists? :raw_meetings_data, :has_attachments
    add_column :raw_meetings_data, :is_reminder_on, :boolean unless column_exists? :raw_meetings_data, :is_reminder_on
  end
end
