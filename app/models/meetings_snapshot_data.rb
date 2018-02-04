class MeetingsSnapshotData < ActiveRecord::Base
  belongs_to :snapshot
  belongs_to :company
  has_many :meeting_attendees

  enum meeting_type: [:single, :recurring]
end
