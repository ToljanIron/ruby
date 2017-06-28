require 'spec_helper'

include FactoryGirl::Syntax::Methods

IN = 'to_employee_id'
OUT  = 'from_employee_id'

INIT ||= 1
REPLY ||= 2
FWD ||= 3

TO_TYPE ||= 1
CC_TYPE ||= 2
BCC_TYPE ||= 3

# This test file is for new algorithms for meetings - part of V3 version

describe AlgorithmsHelper, type: :helper do
  
  before(:all) do
    
    @cid = 9
    @s = FactoryGirl.create(:snapshot, name: 'meetings test snapshot', company_id: @cid)
    
    em1 = 'p11@email.com'
    em2 = 'p22@email.com'
    em3 = 'p33@email.com'
    em4 = 'p44@email.com'
    em5 = 'p55@email.com'
    em6 = 'p66@email.com'

    @e1 = FactoryGirl.create(:employee, id: 1001, email: em1, company_id: @cid)
    @e2 = FactoryGirl.create(:employee, id: 1002, email: em2, company_id: @cid)
    @e3 = FactoryGirl.create(:employee, id: 1003, email: em3, company_id: @cid)
    @e4 = FactoryGirl.create(:employee, id: 1004, email: em4, company_id: @cid)
    @e5 = FactoryGirl.create(:employee, id: 1005, email: em5, company_id: @cid)
    @e6 = FactoryGirl.create(:employee, id: 1006, email: em6, company_id: @cid)
  end

  after(:each) do
    MeetingsSnapshotData.delete_all
    MeetingAttendee.delete_all
  end

  describe 'Algorithm name: in the loop | meeting invitations in degree | type: measure' do
    before(:all) do

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
    before(:all) do

      meeting1 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid)
      meeting2 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid)
      meeting3 = MeetingsSnapshotData.create!(snapshot_id: @s.id, company_id: @cid)

      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e2.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e3.id)
      MeetingAttendee.create!(meeting_id: meeting1.id, employee_id: @e6.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e1.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e4.id)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e6.id, response: 3)
      MeetingAttendee.create!(meeting_id: meeting2.id, employee_id: @e5.id, response: 3)
      MeetingAttendee.create!(meeting_id: meeting3.id, employee_id: @e5.id, response: 3)

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
  end
end