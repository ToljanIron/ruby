require 'faker'

[94, 145].each do |sid|
  puts "Working on sid: #{sid}"
  ## Clear old data
  puts "Deleting old meetings"
  mids = MeetingsSnapshotData.where(snapshot_id: sid)
  MeetingAttendee.where(meeting_id: mids).delete_all
  MeetingsSnapshotData.where(id: mids).delete_all

  ## Create new data
  puts "Going to create 20 meetings now"
  empsarr = Employee.where(snapshot_id: sid).select(:id).pluck(:id)

  (0..20).each do |ii|
    puts "Meeting number: #{ii}"

    r = rand(1..100)
    meeting_type = 0 if r <= 70
    meeting_type = 1 if r >  70

    m = MeetingsSnapshotData.create!(
      subject: Faker::Lorem.word,
      meeting_room_id: 1,
      snapshot_id: sid,
      duration_in_minutes: 1 + Random.rand(120),
      start_time: Faker::Time.between(30.days.ago, Time.now),
      meeting_type: meeting_type
    )
    meetingsize = (Random.rand * 6).floor
    empsinmeeting = empsarr.sample(meetingsize)
    empsinmeeting.each do |eid|
      MeetingAttendee.create!(
        meeting_id: m.id,
        employee_id: eid
      )
    end
  end
end
