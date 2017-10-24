require 'faker'

  companyid = 11
  sid=94
  MeetingsSnapshotData.delete_all
  MeetingAttendee.delete_all
  MeetingRoom.delete_all

empnum = Employee.where(snapshot_id: sid).count
emparr = Employee.where(snapshot_id: sid).sample(empnum*0.75)
recent_snapshot = Snapshot.find(sid)

(0..5).each do |i|
  MeetingRoom.find_or_create_by!(id: i, name: Faker::Address.state, office_id: 1)
end

#Generates (1/5 of the number of employees) meetings and randomly populates each meeting with different number of employees
(0..((empnum/5).to_i)).each do |i|
  MeetingsSnapshotData.find_or_create_by!(id: i, subject: Faker::Lorem.word,   meeting_room_id: Random.rand(5), snapshot_id: recent_snapshot.id,
                            duration_in_minutes: 1 + Random.rand(300), start_time: Faker::Time.between(30.days.ago, Time.now),
                            company_id: companyid, meeting_uniq_id: Faker::Lorem.word)
  meetingatt = emparr.sample((2 + Random.rand(empnum - 2)/6).to_i) #The "/6).to_i" has been added to make meetings smaller, can be removed if no meeting size limit is needed
    (0..(meetingatt.length.to_i)).each do |j|
      MeetingAttendee.find_or_create_by!(meeting_id: i, employee_id: meetingatt[j-1].id)
    end
end

# end

  # Company.find_or_create_by!(id: 1, name: "Hevra10")
  # # Snapshot.find_or_create_by!(id: 8, name: "2016-01", company_id: 1)

  # Group.find_or_create_by!(id: 1, name: "R&D",         company_id: 1,                     color_id: 10)
  # Group.find_or_create_by!(id: 2, name: "R&R",         company_id: 1, parent_group_id: 1, color_id: 11)
  # Group.find_or_create_by!(id: 3, name: "D&D",         company_id: 1, parent_group_id: 1, color_id: 12)
  # Group.find_or_create_by!(id: 99, name: "NoMeetings", company_id: 1, parent_group_id: 1, color_id: 13)
  # Group.find_or_create_by!(id: 10, name: "MARKETING",  company_id: 1,                     color_id: 10)
  # Group.find_or_create_by!(id: 11, name: "ONLINE",     company_id: 1, parent_group_id:10, color_id: 11)
  # Group.find_or_create_by!(id: 12, name: "OFFLINE",    company_id: 1, parent_group_id:10, color_id: 12)
  # Group.find_or_create_by!(id: 20, name: "MAIL",       company_id: 1, parent_group_id:12, color_id: 13)
  # Group.find_or_create_by!(id: 13, name: "LINE",       company_id: 1, parent_group_id:10, color_id: 13)
  # Group.find_or_create_by!(id: 30, name: "SUBLINE",    company_id: 1, parent_group_id:13, color_id: 13)

  # Employee.find_or_create_by!(id: 1,  company_id: 1, group_id: 1, email: "bov@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi")
  # Employee.find_or_create_by!(id: 2,  company_id: 1, group_id: 1, email: "fru@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi")
  # Employee.find_or_create_by!(id: 3,  company_id: 1, group_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi")
  # Employee.find_or_create_by!(id: 5,  company_id: 1, group_id: 2, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi")
  # Employee.find_or_create_by!(id: 8,  company_id: 1, group_id: 2, email: "fra@mail.com", external_id: "10011", first_name: "Fra", last_name: "Levi")
  # Employee.find_or_create_by!(id: 13, company_id: 1, group_id: 2, email: "gat@mail.com", external_id: "10014", first_name: "Gar", last_name: "Levi")
  # Employee.find_or_create_by!(id: 21, company_id: 1, group_id: 3, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi")
  # Employee.find_or_create_by!(id: 34, company_id: 1, group_id: 3, email: "bo@mail.com", external_id: "10023", first_name: "Bob", last_name: "Levi")
  # Employee.find_or_create_by!(id: 55, company_id: 1, group_id: 9, email: "no@mail.com", external_id: "10093", first_name: "Lob", last_name: "Bevi")

  # Employee.find_or_create_by!(id: 89,    company_id: 1, group_id: 11, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 144,   company_id: 1, group_id: 11, email: "hal@mail.com", external_id: "10015", first_name: "Bob", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 233,   company_id: 1, group_id: 11, email: "gur@mail.com", external_id: "10016", first_name: "Fra", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 377,   company_id: 1, group_id: 12, email: "gir@mail.com", external_id: "10017", first_name: "Gur", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 610,   company_id: 1, group_id: 12, email: "gor@mail.com", external_id: "10018", first_name: "Bub", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 987,   company_id: 1, group_id: 20, email: "get@mail.com", external_id: "10019", first_name: "Fru", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 1597,  company_id: 1, group_id: 20, email: "gey@mail.com", external_id: "10021", first_name: "Gor", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 2584,  company_id: 1, group_id: 13, email: "geu@mail.com", external_id: "10022", first_name: "Gir", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 4181,  company_id: 1, group_id: 13, email: "gei@mail.com", external_id: "10024", first_name: "zim", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 6765,  company_id: 1, group_id: 13, email: "geo@mail.com", external_id: "10025", first_name: "sir", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 10946, company_id: 1, group_id: 13, email: "gep@mail.com", external_id: "10026", first_name: "nozim", last_name: "Cohen")
  # Employee.find_or_create_by!(id: 17711, company_id: 1, group_id: 30, email: "geq@mail.com", external_id: "10027", first_name: "Gar", last_name: "Cohen")

  # MeetingRoom.find_or_create_by!(name: 'room1', office_id: 1)
  # MeetingRoom.find_or_create_by!(name: 'room2', office_id: 1)
  # MeetingRoom.find_or_create_by!(name: 'room3', office_id: 1)
  # MeetingRoom.find_or_create_by!(name: 'room4', office_id: 2)

  # Meeting.find_or_create_by!(subject: 'group1: 2, group2: 2 group3: 1 group11: 1',   meeting_room_id: 1, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting1')
  # Meeting.find_or_create_by!(subject: 'group1: 3',                                   meeting_room_id: 2, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting2')
  # Meeting.find_or_create_by!(subject: 'group3: 1 group12: 2 group20: 2 group13: 3',  meeting_room_id: 3, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting3')
  # Meeting.find_or_create_by!(subject: 'group1: 2 group3: 1 group 30: 1',             meeting_room_id: 4, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting4')
  # Meeting.find_or_create_by!(subject: 'group13: 1 group20: 2 group30: 1',            meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting5')

  # MeetingAttendee.find_or_create_by(meeting_id: 1, attendee_id: 1,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 1, attendee_id: 2,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 1, attendee_id: 8,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 1, attendee_id: 13, attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 1, attendee_id: 21, attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 1, attendee_id: 89, attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 2, attendee_id: 1,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 2, attendee_id: 2,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 2, attendee_id: 3,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 3, attendee_id: 34,   attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 3, attendee_id: 377,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 3, attendee_id: 610,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 3, attendee_id: 987,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 3, attendee_id: 1597, attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 3, attendee_id: 2584, attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 3, attendee_id: 4181, attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 3, attendee_id: 6765, attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 4, attendee_id: 1,      attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 4, attendee_id: 3,      attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 4, attendee_id: 34,     attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 4, attendee_id: 17711,  attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 5, attendee_id: 4181,   attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 5, attendee_id: 987,    attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 5, attendee_id: 1597,   attendee_type:0)
  # MeetingAttendee.find_or_create_by(meeting_id: 5, attendee_id: 17711,  attendee_type:0)
