class MeetingAttendee < ActiveRecord::Base
  belongs_to :meetings_snapshot_data
  # enum participant_type: [:employee, :external_domain]
  enum response: [:accept, :tentative, :decline]
  after_initialize :init

end

def init
  self.attendee_type ||= 0
end
