# frozen_string_literal: true
require 'base64'

module RawMeetingsDataHelper

  def process_meetings_request(request_parsed_to_csv)

    company_id = request_parsed_to_csv['company_id']

    zipped_str = Base64.decode64(request_parsed_to_csv['file'])

    company = Company.where(id: company_id)[0]

    raise "process_meetings_request: Cannot find company with id #{company_id}" if company.nil?

    return if zipped_str.empty?
    csv = zip_to_csv(zipped_str)
    data = CSV.parse(csv)

    raise 'process_meetings_request: Cannot process more then 500 meetings' if data.length > 500

    data.shift
    data.each do |meeting|
      start_time = format_meeting_item(meeting[2])
      end_time = format_meeting_item(meeting[3])

      incoming_entry = RawMeetingsData.new(
        organizer: format_meeting_item(meeting[0]),
        subject:  format_meeting_item(meeting[1]),
        start_time: start_time,
        duration_in_minutes: get_duration(start_time, end_time),
        location: format_meeting_item(meeting[4]),
        meeting_type: get_type(format_meeting_item(meeting[5])),
        attendees: format_meeting_item(meeting[6]),
        is_cancelled: format_meeting_item(meeting[7]),
        show_as: get_show_as(format_meeting_item(meeting[8])),
        importance: get_importance(format_meeting_item(meeting[9])),
        has_attachments: format_meeting_item(meeting[10]),
        is_reminder_on: format_meeting_item(meeting[11]),
        external_meeting_id: format_meeting_item(meeting[12]),
        company_id: company_id
      )
      existing_meeting = get_meeting(incoming_entry.company_id,
        incoming_entry.external_meeting_id, incoming_entry.subject,
        incoming_entry.start_time, incoming_entry.location)

      # existing_meeting = RawMeetingsData.where(company_id: incoming_entry.company_id, external_meeting_id: incoming_entry.external_meeting_id).first

      # Found meeting - update fields
      if(!existing_meeting.nil?)
        update_meeting_entry_in_db(incoming_entry, existing_meeting)
        next
      end
      begin
        incoming_entry.save!
      rescue Exception => e
        # If this is a duplicate entry as defined by the table indices - continue to the next entry
        next if e.message.include? "PG::UniqueViolation"
        raise e
      end
    end
  end

  def format_meeting_item(item, rm_quote = true)
    return nil if item.blank?
    return rm_quote ? item.delete("'") : item
  end

  def get_meeting(company_id, external_meeting_id, subject, start_time, location)
    if external_meeting_id
      return RawMeetingsData.where(company_id: company_id, external_meeting_id: external_meeting_id).first
    else
      return RawMeetingsData.where(
        company_id: company_id,
        subject: subject,
        start_time: start_time,
        location: location
        ).first
    end
  end

  def update_meeting_entry_in_db(incoming_entry, existing_meeting)
    existing_meeting[:organizer] = incoming_entry[:organizer]
    existing_meeting[:subject] = incoming_entry[:subject]
    existing_meeting[:start_time] = incoming_entry[:start_time]
    existing_meeting[:duration_in_minutes] = incoming_entry[:duration_in_minutes]
    existing_meeting[:location] = incoming_entry[:location]
    existing_meeting[:attendees] = incoming_entry[:attendees]
    existing_meeting[:is_cancelled] = incoming_entry[:is_cancelled]
    existing_meeting[:has_attachments] = incoming_entry[:has_attachments]
    existing_meeting[:is_reminder_on] = incoming_entry[:is_reminder_on]
    existing_meeting[:meeting_type] = incoming_entry[:meeting_type]
    existing_meeting[:show_as] = incoming_entry[:show_as]
    existing_meeting[:importance] = incoming_entry[:importance]

    existing_meeting.save!
  end

  def format_date(d)
    return d[0..9]
  end

  def zip_to_csv(zipped_str)
    ZipRuby::Archive.open_buffer(zipped_str) do |archive|
      archive.each do |entry|
        return entry.read
      end
    end
    rescue
      return -1
  end

  def get_type(type)
    type_value = nil

    case type.downcase
    when 'singleInstance'
      type_value = 0
    when 'occurrence'
      type_value = 1
    end
    return type_value
  end

  def get_show_as(show_as)
    show_as_value = nil

    case show_as.downcase
    when 'free'
      show_as_value = 0
    when 'workingelsewhere'
      show_as_value = 1
    when 'tentative'
      show_as_value = 2
    when 'busy'
      show_as_value = 3
    when 'oof'
      show_as_value = 4
    end
    return show_as_value
  end

  def get_importance(importance)
    importance_value = nil

    case importance.downcase
    when 'low'
      importance_value = 0
    when 'normal'
      importance_value = 1
    when 'high'
      importance_value = 2
    end
    return importance_value
  end

  def get_duration(start_time, end_time)
    duration = 0 

    return duration if (start_time.nil? || end_time.nil?)
    duration = (Time.parse(end_time) - Time.parse(start_time))/60
    return duration.round
  end
end

