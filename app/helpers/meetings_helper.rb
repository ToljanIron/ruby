module MeetingsHelper
  MEETING_ATTRIBUTES = %w(meeting_uniq_id company_id snapshot_id meeting_room_id start_time duration_in_minutes subject organizer_id).freeze
  ATTENDEES_ATTRIBUTES = %w(meeting_id employee_id).freeze

  def self.create_meetings_for_snapshot(sid, start_date, end_date)
    relevant_meetings = RawMeetingsData.where('start_time >= ?', start_date).where('start_time < ?', end_date)
    cid = Snapshot.find(sid)[:company_id]
    create_meetings_and_attendees(relevant_meetings, cid, sid)
  end

  def self.create_meetings_and_attendees(relevant_meetings, cid, sid)
    meetings_values = []
    meetings_attendees = {}
      #puts "}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} 1"
    relevant_meetings.each do |raw_meeting|
      meeting_value = raw_meeting.convert_to_param_array(cid, sid)
      #puts "}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} 2"
      next if meeting_value.nil?

      meetings_values << "(#{raw_meeting.convert_to_param_array(cid, sid).try(:join, ',')})"
      #puts "}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} 2.5"
      #ap meetings_values

      meeting_identifier = RawMeetingsData.meeting_identifier(
        raw_meeting[:subject], raw_meeting[:organizer]
      )
    #puts "}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} 3"
    #puts raw_meeting[:attendees]
    #ap raw_meeting
    #puts "}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} 4"
      meetings_attendees[meeting_identifier] =
        raw_meeting[:attendees]
          .tr('\"', '')
          .tr('[]','')
          .tr('{}', '')
          .split(',')
    end
    return if meetings_values.empty?
    sql = "INSERT INTO meetings_snapshot_data (#{MEETING_ATTRIBUTES.join(',')})
       VALUES #{meetings_values.join(',')}"
    #puts "}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} 5"
    #puts sql
    ActiveRecord::Base.connection.execute( sql )

    #puts "}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} 5.1"
    #ap meetings_attendees
    create_attendees(meetings_attendees, sid)
  end

  def self.create_attendees(meetings_attendees, sid)
    return if meetings_attendees.empty?
    attendees_values = []
    meetings_attendees.each do |uniq_id, attendees|
      meeting = MeetingsSnapshotData.find_by(meeting_uniq_id: uniq_id)
      cid = meeting.company_id
      attendees_converted = convert_attendees_to_attendee_entries(attendees, cid, meeting.id, sid)
      attendees_values << attendees_converted
    end
    return if attendees_values.empty?
    ActiveRecord::Base.connection.execute(
      "INSERT INTO meeting_attendees (#{ATTENDEES_ATTRIBUTES.join(',')})
       VALUES #{attendees_values.join(',')}")
  end

  def self.convert_attendees_to_attendee_entries(attendees_emails, cid, meeting_id, sid)
    return attendees_emails.map do |email|
      email = email.downcase.strip.tr("'\"", '')
      if in_company_domain?(email, cid)
        id = EmailPropertiesTranslator.convert_email_to_employee_id(email, cid, sid)
      else
        id = convert_email_to_external_entity_id(email, cid)
      end
      '(' + [meeting_id, id].join(',') + ')'
    end.join(',')
  end

  def self.convert_email_to_external_entity_id(email, cid)
    external_domain_type_id = OverlayEntityType.find_or_create_by(overlay_entity_type: 0, name: 'external_domains').id
    external_entity = OverlayEntity.find_or_create_by(overlay_entity_type_id: external_domain_type_id, name: email, company_id: cid)
    if external_entity.overlay_entity_group.nil?
      group = OverlayEntityGroup.find_or_create_by(overlay_entity_type_id: external_domain_type_id, name: email.split('@')[1], company_id: cid)
      external_entity.update(overlay_entity_group_id: group.id)
    end
    external_entity.id
  end

  def self.in_company_domain?(email, cid)
    company_domains = Domain.where(company_id: cid).pluck(:domain)
    return company_domains.include? email.split('@').last
  end
end
