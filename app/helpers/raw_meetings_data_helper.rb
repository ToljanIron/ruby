# frozen_string_literal: true
module RawMeetingsDataHelper
  def process_meetings_request(request)
    company           = request['company']
    raw_meetings_data = request['meetings']

    comp = Company.where(name: company)[0]
    raise "process_meetings_request: Cannot find company by name '#{company}'" if comp.nil?
    company_id = comp.id

    return if raw_meetings_data.blank?
    raise 'process_meetings_request: Cannot process more then 500 meetings' if raw_meetings_data.length > 500

    raw_meetings_data.each do |meeting|
      subject             = format_meeting_item(meeting['subject'])
      attendees           = format_meeting_item(meeting['attendees'])
      duration_in_minutes = format_meeting_item(meeting['duration_in_minutes'])
      external_meeting_id = format_meeting_item(meeting['external_meeting_id'])
      location            = format_meeting_item(meeting['location'])
      start_time          = !meeting['start_time'].blank? ? meeting['start_time'].to_time : nil
      rmd = get_meeting(company_id, external_meeting_id, subject, start_time, attendees)
      next if rmd
      RawMeetingsData.create!(
        company_id: company_id,
        location: location,
        start_time: start_time,
        attendees:  attendees,
        duration_in_minutes: duration_in_minutes,
        subject:  subject,
        external_meeting_id: external_meeting_id
      )
    end
  end

  def format_meeting_item(item, rm_quote = true)
    return nil if item.blank?
    return rm_quote ? item.delete("'") : item
  end

  def get_meeting(company_id, external_meeting_id, subject, start_time, attendees)
    if external_meeting_id
      return RawMeetingsData.where(company_id: company_id, external_meeting_id: external_meeting_id)
    end
    return RawMeetingsData.where(
      company_id: company_id,
      subject:  subject,
      start_time: start_time,
      attendees: attendees
    ).first
  end

  def format_date(d)
    return d[0..9]
  end
end
