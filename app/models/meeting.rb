class Meeting < ActiveRecord::Base
  belongs_to :snapshot
  belongs_to :company
  has_many :meeting_attendees
end
