class RawMeetingsData < ActiveRecord::Base
  validates :company_id, presence: true
  validates :start_time, presence: true

  enum meeting_type: [:singleInstance, :occurrence]
  enum show_as: [:free, :workingelsewhere, :tentative, :busy, :oof]
  enum importance: [:low, :normal, :high]

  def add_external_id
    return if self[:external_meeting_id]
    update(external_meeting_id: SecureRandom.uuid)
  end

  def convert_to_param_array(cid, sid)
    meeting_uniq_id = Digest::SHA1.hexdigest(
      "#{self[:external_meeting_id]}--#{self[:start_time]}")

    return [
      meeting_uniq_id,
      cid,
      sid,
      meeting_room_id,
      self[:start_time],
      duration_in_minutes,
      self[:subject]
    ].map { |param| param ? "'#{param}'" : 'null' }
  end

  def self.meeting_identifier(subject, organizer)
    return Digest::SHA1.hexdigest(
      "#{subject}-#{organizer}"
    )
  end

  def meeting_room_id
    MeetingRoom.find_by(name: self[:location]).try(:id)
  end

  def duration_in_minutes
    return 60 unless self[:duration_in_minutes]
    hours_and_minutes = self[:duration_in_minutes].split(':')
    hours_and_minutes[0].to_i * 60 + hours_and_minutes[1].to_i
  end
end
