require 'spec_helper'

include FactoryBot::Syntax::Methods

IN = 'to_employee_id'
OUT  = 'from_employee_id'

INIT ||= 1
REPLY ||= 2
FWD ||= 3

TO_TYPE ||= 1
CC_TYPE ||= 2
BCC_TYPE ||= 3

DECLINE ||= 2

# This test file is for new algorithms for meetings - part of V3 version

describe AlgorithmsHelper, type: :helper do

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
  end

  before(:each) do

    @cid = 9
    @s = FactoryBot.create(:snapshot, name: 'meetings test snapshot', company_id: @cid)
    @g = FactoryBot.create(:group, name: 'Test group', company_id: @cid)

    em1 = 'p11@email.com'
    em2 = 'p22@email.com'
    em3 = 'p33@email.com'
    em4 = 'p44@email.com'
    em5 = 'p55@email.com'
    em6 = 'p66@email.com'

    @e1 = FactoryBot.create(:employee, id: 1001, email: em1, company_id: @cid, group_id: @g.id)
    @e2 = FactoryBot.create(:employee, id: 1002, email: em2, company_id: @cid, group_id: @g.id)
    @e3 = FactoryBot.create(:employee, id: 1003, email: em3, company_id: @cid, group_id: @g.id)
    @e4 = FactoryBot.create(:employee, id: 1004, email: em4, company_id: @cid, group_id: @g.id)
    @e5 = FactoryBot.create(:employee, id: 1005, email: em5, company_id: @cid, group_id: @g.id)
    @e6 = FactoryBot.create(:employee, id: 1006, email: em6, company_id: @cid, group_id: @g.id)
  end

  describe 'Algorithm name: in the loop | meeting invitations in degree | type: measure' do
    before(:each) do
      meeting1 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid)
      meeting2 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid)

      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e2.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e3.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e4.id)

      @res = calc_in_the_loop(@s.id)
      # @res.each {|r| puts "#{r}\n"}
    end

    it 'should test higher "meetings indegree"' do
      higher_emp = @e1.id
      lower_emp = @e3.id
      higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
      lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end

    it 'should test zero "meetings indegree"' do
      zero_emp = @e5.id
      zero_measure = @res.select{|r| r[:id]==zero_emp}[0]
      expect(zero_measure[:measure]).to eq(0)
    end
  end

  describe 'Algorithm name: meeting rejecters | rejections devided by invitations | type: relative measure' do
    before(:each) do
      meeting1 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid)
      meeting2 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid)
      meeting3 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid)

      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e2.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e3.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e6.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e4.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e6.id, response: DECLINE)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e5.id, response: DECLINE)
      MeetingAttendee.create!(meeting_id: meeting3.id, employee_id: @e5.id, response: DECLINE)

      @res = calc_rejecters(@s.id)
      # @res.each {|r| puts "#{r}\n"}
    end

    it 'should test higher "rejection degree"' do
      higher_emp = @e5.id
      lower_emp = @e6.id
      higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
      lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end
    it 'should test zero "rejection measure"' do
      zero_emp = @e1.id
      zero_measure = @res.select{|r| r[:id]==zero_emp}[0]
      expect(zero_measure[:measure]).to eq(0)
    end
  end

  describe 'Algorithm name: routiners | recurring devided by invitations | type: relative measure' do
    before(:each) do

      meeting1 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid, meeting_type: 1)
      meeting2 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid, meeting_type: 0)
      meeting3 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid, meeting_type: 0)

      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e2.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e3.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e6.id)

      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e4.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e5.id, response: DECLINE)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e6.id, response: DECLINE)

      MeetingAttendee.create!(meeting_id: meeting3.id, employee_id: @e5.id, response: DECLINE)

      @res = calc_routiners(@s.id)
      # @res.each {|r| puts "#{r}\n"}
    end

    it 'should test higher "routiners degree"' do
      higher_emp = @e3.id
      lower_emp = @e6.id
      higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
      lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end
    it 'should test zero "routiners measure"' do
      zero_emp = @e4.id
      zero_measure = @res.select{|r| r[:id]==zero_emp}[0]
      expect(zero_measure[:measure]).to eq(0)
    end
  end

  describe 'Algorithm name: inviters | invitations out degree (times employee organized a meeting) | type: measure' do
    before(:each) do
      meeting1 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid, meeting_type: 1, organizer_id: @e1.id)
      meeting2 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid, meeting_type: 0, organizer_id: @e1.id)
      meeting3 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid, meeting_type: 0, organizer_id: @e2.id)

      @res = calc_inviters(@s.id)
      # @res.each {|r| puts "#{r}\n"}
    end

    it 'should test higher "inviters (organized) degree"' do
      higher_emp = @e1.id
      lower_emp = @e2.id
      higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
      lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end
    it 'should test zero "inviters (organized) measure"' do
      zero_emp = @e5.id
      zero_measure = @res.select{|r| r[:id]==zero_emp}[0]
      expect(zero_measure[:measure]).to eq(0)
    end
  end

  describe 'Algorithm name: average number of ppl in meetings | (implied in name...) | type: gauge' do
    before(:each) do

      meeting10 = MeetingsSnapshotData.create!(id: 10, snapshot_id: @s.id, company_id: @cid, meeting_type: 1)
      meeting11 = MeetingsSnapshotData.create!(id: 11, snapshot_id: @s.id, company_id: @cid, meeting_type: 0)
      meeting12 = MeetingsSnapshotData.create!(id: 12, snapshot_id: @s.id, company_id: @cid, meeting_type: 0)

      MeetingAttendee.create!(meeting_id: meeting10.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting10.id, employee_id: @e2.id)
      MeetingAttendee.create!(meeting_id: meeting10.id, employee_id: @e3.id)
      MeetingAttendee.create!(meeting_id: meeting10.id, employee_id: @e4.id, response: DECLINE)
      MeetingAttendee.create!(meeting_id: meeting10.id, employee_id: @e6.id)

      MeetingAttendee.create!(meeting_id: meeting11.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting11.id, employee_id: @e4.id)
      MeetingAttendee.create!(meeting_id: meeting11.id, employee_id: @e6.id, response: DECLINE)

      MeetingAttendee.create!(meeting_id: meeting12.id, employee_id: @e2.id)

      @res = calc_avg_num_of_ppl_in_meetings(@s.id, 1)
    end

    it 'should test average number of ppl in meetings' do
      expect(@res[0][:measure] - 2.33).to be < 0.001
    end
  end
end
