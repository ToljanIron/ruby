require 'spec_helper'

describe RawMeetingsDataHelper, :type => :helper do
  describe ', process_meetings_request' do
    it ',with invalid request should raise exception' do
      expect { process_meetings_request nil }.to raise_exception
      expect { process_meetings_request 'nil' }.to raise_exception
    end

    describe ',with valid request' do
      before do
        Company.create(name: 'some company')
        @contents =
          [{'subject' => 'planinig SA', 'location' => 'Lobby', 'duration_in_minutes' => '90', 'attendees' => '{email1@company.com,email2@company.com,email3@company.com}', 'start_time' => '2015-07-14T08:56:24+03:00' },
           {'subject' => 'planinig SA', 'duration_in_minutes' => '90', 'attendees' => '{email44433@company.com,email2@company.com,email3@company.com}', 'start_time' => '2015-07-14T08:56:24+03:00' }]
        @req = { 'company' => 'some company', 'meetings' => @contents }
      end
      after do
        DatabaseCleaner.clean_with(:truncation)
      end

      it 'should not raise exception' do
        expect { process_meetings_request @req }.not_to raise_exception
      end

      it 'should write to the db' do
        process_meetings_request @req
        expect(RawMeetingsData.count).to be > 0
        expect(RawMeetingsData.last.subject).not_to be(nil)
        expect(RawMeetingsData.last.location).to be(nil)
      end

      it 'should be able to handle gracefully a duplicate insert' do
        puts "raw data count 1: #{RawMeetingsData.count}"
        process_meetings_request @req
        puts "raw data count 2: #{RawMeetingsData.count}"
        process_meetings_request @req
        puts "raw data count 3: #{RawMeetingsData.count}"
      end

      it 'should be create only one raw if start_time + location + attendees' do
        @contents.push({'subject' => 'iteration SA', 'location' => 'esacpe room', 'duration' => '5:30', 'attendees' => '{email6@company.com}', 'start_time' => '2015-07-14T08:56:24+03:00' })
        @contents.push({'subject' => 'iteration SA', 'location' => 'bb room', 'duration' => '5:30', 'attendees' => '{email6@company.com}', 'start_time' => '2015-07-14T08:56:24+03:00' })
        @req = { 'company' => 'some company', 'meetings' => @contents }
        process_meetings_request @req
        expect(RawMeetingsData.count).to eq(3)
      end

      it 'should be able to add a new raw with extrnal_meeting_id' do
        @contents.push({'subject' => 'iteration SA', 'external_meeting_id' => 'dspo2342ddodo', 'location' => 'esacpe room', 'duration_in_minutes' => '330', 'attendees' => '{email6@company.com}', 'start_time' => '2015-07-14T08:56:24+03:00' })
        @contents.push({'subject' => 'iteration wow SA', 'external_meeting_id' => 'dspo2342ddodo', 'location' => 'bb room', 'duration_in_minutes' => '330', 'attendees' => '{email3@company.com}', 'start_time' => '2015-07-14T08:56:24+03:00' })
        @req = { 'company' => 'some company', 'meetings' => @contents }
        process_meetings_request @req
        expect(RawMeetingsData.count).to eq(2)
        expect(RawMeetingsData.last.external_meeting_id).not_to be('dspo2342ddodo')
      end
    end
  end
end
