class MeetingAttendee < ActiveRecord::Base
  belongs_to :meeting
  enum participant_type: [:employee, :external_domain]
  after_initialize :init
end

def init
  self.attendee_type ||= 0
end
