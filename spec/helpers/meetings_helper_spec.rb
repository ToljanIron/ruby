require 'spec_helper'
require './spec/spec_factory'

include FactoryBot
include FactoryBot::Syntax::Methods

describe MeetingsHelper, type: :helper do

  before do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
  end

  describe 'create_meetings_and_attendees' do
    before do
      Company.create!(id:1, name: 'Acme')
      Snapshot.create!(id: 1, company_id: 1, timestamp: '2018-11-02 12:12:12'.to_time)
      FactoryBot.create(:employee, email: 'e1@m.com')
      FactoryBot.create(:employee, email: 'e2@m.com')
      FactoryBot.create(:employee, email: 'e3@m.com')
      meetings = [
        {
          subject: 'meeting 1',
          attendees: "[\"e1@m.com\", \"e2@m.com\"]",
          company_id: 1,
          start_time: '2018-11-02 12:12:12'.to_time,
          organizer: 'e3@m.com'
        }
      ]
      RawMeetingsData.create!(meetings[0])
    end

    it 'should work' do
      ap RawMeetingsData.all

      MeetingsHelper.create_meetings_for_snapshot(
        1,
        '2018-11-01'.to_time,
        '2018-11-03'.to_time)

      puts "=================================="
      ap MeetingsSnapshotData.all
      puts "=================================="
      ap MeetingAttendee.all
      puts "=================================="

    end
  end

  describe 'create_meetings_for_snapshot' do
    before do
      Company.create(name: 'new comp', id: 1)
      @snapshot = create(:snapshot)
      @raw_meeting = create(:raw_meetings_data)
    end

    it 'should create a meeting for a raw meeting in a time period between start_date and end_date' do
      MeetingsHelper.create_meetings_for_snapshot(@snapshot.id, 4.weeks.ago, Time.zone.now)
      expect(Meeting.count).to eq(1)
    end

    it 'should not create a meeting for a raw meeting outside the time period' do
      MeetingsHelper.create_meetings_for_snapshot(@snapshot.id, 4.weeks.ago, 3.weeks.ago)
      expect(Meeting.count).to eq(0)
    end

    it 'should write to the db' do
      @raw_meeting.update(external_meeting_id: 'abcd')
      MeetingsHelper.create_meetings_for_snapshot(@snapshot.id, 4.weeks.ago, Time.zone.now)
      expect(Meeting.count).to eq(1)
      expect(Meeting.first[:subject]).to eq(@raw_meeting[:subject])
      expect(Meeting.first[:company_id]).to eq(1)
      expect(Meeting.first[:meeting_uniq_id]).to eq('abcd')
    end
  end

  describe 'create_meeting_attendees' do
    before do
      Company.create(name: 'new comp', id: 1)
      Domain.create(company_id: 1, domain: 'company.com')
      @snapshot = create(:snapshot)
      FactoryBot.create(:meeting, meeting_uniq_id: 'abcd', snapshot_id: @snapshot.id)
    end

    it 'should create meeting attendees for emps' do
      create(:employee, email: 'email1@company.com')
      create(:employee, email: 'email2@company.com')
      create(:employee, email: 'email3@company.com')
      MeetingsHelper.create_attendees({'abcd': ['email1@company.com', 'email2@company.com', 'email3@company.com']}, @snapshot.id)
      expect(MeetingAttendee.count).to eq(3)
      expect(MeetingAttendee.first[:employee_id]).to eq(1)
      expect(MeetingAttendee.second[:employee_id]).to eq(2)
      expect(MeetingAttendee.last[:employee_id]).to eq(3)
    end

    it 'should create meeting attendees for emps if given aliases' do
      create(:employee, email: 'email1@company.com')
      EmployeeAliasEmail.create(employee_id: 1, email_alias: 'e1@company.com')
      MeetingsHelper.create_attendees({'abcd': ['e1@company.com']}, @snapshot.id)
      expect(MeetingAttendee.count).to eq(1)
      expect(MeetingAttendee.first[:employee_id]).to eq(1)
    end

    it 'should create meeting attendees for external domains if they exist' do
      OverlayEntityType.create(overlay_entity_type: 0, name: 'external_domains')
      OverlayEntityGroup.create(name: 'domain.com', overlay_entity_type_id: 1, company_id: 1)
      OverlayEntity.create(name: 'first@domain.com', overlay_entity_group_id: 1, overlay_entity_type_id: 1, company_id: 1)
      MeetingsHelper.create_attendees({'abcd': ['first@domain.com']}, @snapshot.id)
      expect(MeetingAttendee.count).to eq(1)
      expect(MeetingAttendee.first[:employee_id]).to eq(1)
    end

    it 'should create external domains for unknown emails' do
      OverlayEntityType.create(overlay_entity_type: 0, name: 'external_domains')
      OverlayEntityGroup.create(name: 'domain.com', overlay_entity_type_id: 1, company_id: 1)
      MeetingsHelper.create_attendees({'abcd': ['first@domain.com']}, @snapshot.id)
      expect(OverlayEntity.count).to eq(1)
      expect(OverlayEntity.first[:name]).to eq('first@domain.com')
      expect(OverlayEntity.first[:overlay_entity_group_id]).to eq(1)
      expect(OverlayEntity.first[:overlay_entity_type_id]).to eq(1)
    end

    it 'should create external domains and groups for unknown emails' do
      OverlayEntityType.create(overlay_entity_type: 0, name: 'external_domains')
      MeetingsHelper.create_attendees({'abcd': ['first@domain.com']}, @snapshot.id)
      expect(OverlayEntityGroup.count).to eq(1)
      expect(OverlayEntityGroup.first[:name]).to eq('domain.com')
      expect(OverlayEntityGroup.first[:overlay_entity_type_id]).to eq(1)
    end

    it 'should create meeting attendees for unknown emails' do
      OverlayEntityType.create(overlay_entity_type: 0, name: 'external_domains')
      OverlayEntityGroup.create(name: 'domain.com', overlay_entity_type_id: 1, company_id: 1)
      MeetingsHelper.create_attendees({'abcd': ['first@domain.com']}, @snapshot.id)
      expect(MeetingAttendee.count).to eq(1)
      expect(MeetingAttendee.first[:employee_id]).to eq(1)
    end
  end
end
