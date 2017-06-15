class RawMeetingsData < ActiveRecord::Base
  validates :company_id, presence: true
  validates :start_time, presence: true

  def add_external_id
    return if self[:external_meeting_id]
    update(external_meeting_id: SecureRandom.uuid)
  end

  def convert_to_param_array(cid, sid)
    return [
      self[:external_meeting_id],
      cid,
      sid,
      meeting_room_id,
      self[:start_time],
      duration_in_minutes,
      self[:subject]
    ].map { |param| param ? "'#{param}'" : 'null' }
  end

  def meeting_room_id
    MeetingRoom.find_by(name: self[:location]).try(:id)
  end

  def duration_in_minutes
    hours_and_minutes = self[:duration_in_minutes].split(':')
    hours_and_minutes[0].to_i * 60 + hours_and_minutes[1].to_i
  end
end
