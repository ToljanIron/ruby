require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryGirl::Syntax::Methods

include CompanyWithMetricsFactory

describe AlgorithmsHelper, type: :helper do
  let(:emp1) { FactoryGirl.create(:employee, email: 'e1@e.com', company_id: 1) }
  let(:emp2) { FactoryGirl.create(:employee, email: 'e2@e.com', company_id: 1) }

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'friendship Test results with pin subsets' do
    before(:each) do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 0)
      @s = Snapshot.create(name: 's3', company_id: 0)

      em0 = 'p0@email.com'
      em1 = 'p1@email.com'
      em2 = 'p2@email.com'
      em3 = 'p3@email.com'
      em4 = 'p4@email.com'

      @n1 = FactoryGirl.create(:network_name, name: 'FriendShip', company_id: 0)
      @g1 = FactoryGirl.create(:group, name: 'group_1', company_id: 0)
      @g2 = FactoryGirl.create(:group, name: 'group_2', company_id: 0, parent_group_id: 1)
      @g3 = FactoryGirl.create(:group, name: 'group_3', company_id: 0)

      e0 = FactoryGirl.create(:employee, email:  em0, group_id: 2)
      e1 = FactoryGirl.create(:employee, email:  em1, group_id: 2)
      e2 = FactoryGirl.create(:employee, email:  em2, group_id: 1)
      e3 = FactoryGirl.create(:employee, email:  em3, group_id: 3)
      e4 = FactoryGirl.create(:employee, email:  em4, group_id: 3)

      NetworkSnapshotData.create(from_employee_id: e0.id, to_employee_id: e1.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e0.id, to_employee_id: e3.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e1.id, to_employee_id: e0.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e1.id, to_employee_id: e2.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e1.id, to_employee_id: e3.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e2.id, to_employee_id: e0.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e2.id, to_employee_id: e1.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e2.id, to_employee_id: e3.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e3.id, to_employee_id: e0.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e3.id, to_employee_id: e1.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e3.id, to_employee_id: e2.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e3.id, to_employee_id: e4.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e4.id, to_employee_id: e0.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e4.id, to_employee_id: e1.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e4.id, to_employee_id: e2.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e4.id, to_employee_id: e3.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e0.id, to_employee_id: e2.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)

      @pin = Pin.create(company_id: 0, name: 'testpin', definition: 'some def')
      EmployeesPin.create(pin_id: @pin.id, employee_id: e0.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e1.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e2.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e3.id)
    end

    it ', in degree for employee_id 4 should be 1 ' do
      res = get_list_of_employees_in(1, @pin.id, -1)
      res.each do |row|
        expect(row['sum'].to_i).to eq(1) if row['employee_id'].to_i == 4
      end
    end

    it ', in degree for employee_id 3 should be 2 ' do
      res = get_list_of_employees_in(1, @pin.id, -1)
      res.each do |row|
        expect(row['sum'].to_i).to eq(2) if row['employee_id'].to_i == 3
      end
    end

    it 'should return an array instead of ActiveRecord::Result' do
      res = get_array_of_employees_in(1, @pin.id, -1)
      expect(res.class).to eq(Array)
      expect(res[0].class).to eq(Fixnum)
    end

    it ', out degree for employee_id 2 should be 2' do
      res = get_list_of_employees_out(1, @pin.id, -1)
      res.each do |row|
        expect(row['sum'].to_i).to eq(2) if row['employee_id'].to_i == 2
      end
    end

    it ', f_in_n degree for employee_id 4 should be 0.5' do
      res = get_friends_relation_in_network(1, 1, @pin.id, -1, 'in')
      measure = 0
      res.each do |row|
        measure = row[:measure].to_f if row[:id].to_i == 4
      end
      expect(measure).to eq(0.5)
    end

    it ', Check most isolated' do
      res = most_isolated_workers(1, 1, @pin.id)
      ap res
      measure = 0
      res.each do |row|
        measure = row[:measure].to_f if row[:id].to_i == 3
      end
      expect(measure).to eq(0.25)
    end

    describe 'for a group '
    it ', f_in_n degree for group number 1 should have 3 results' do
      res = get_friends_relation_in_network(1, 1, -1, 1, 'in')
      expect(res.length).to eq(3)
    end

    it ', f_in_n degree for group number 3 should have 2 results' do
      res = get_friends_relation_in_network(1, 1, -1, 3, 'in')
      expect(res.length).to eq(2)
    end

    it ', f_in_n degree for all company' do
      res = get_friends_relation_in_network(1, 1, -1, -1, 'in')
      expect(res.length).to eq(5)
    end
    it ', f_in_n degree for illegal choice of parameters should raise error' do
      expect { get_friends_relation_in_network(1, 1, 1, 0, 'in') }.to raise_error
    end
  end

  describe 'Test results of most social power' do
    before(:each) do
      DatabaseCleaner.clean_with(:truncation)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 0)
      @s = snapshot_factory_create({name: 's1', company_id: 0})
      em0 = 'p0@email.com'
      em1 = 'p1@email.com'
      em2 = 'p2@email.com'
      em3 = 'p3@email.com'
      em4 = 'p4@email.com'

      @g1 = FactoryGirl.create(:group, name: 'group_1', company_id: 0)
      @g2 = FactoryGirl.create(:group, name: 'group_2', company_id: 0, parent_group_id: 1)
      @g3 = FactoryGirl.create(:group, name: 'group_3', company_id: 0)

      e0 = FactoryGirl.create(:employee, email:  em0, group_id: 2)

      e1 = FactoryGirl.create(:employee, email:  em1, group_id: 2)
      e2 = FactoryGirl.create(:employee, email:  em2, group_id: 1)
      e3 = FactoryGirl.create(:employee, email:  em3, group_id: 3)
      e4 = FactoryGirl.create(:employee, email:  em4, group_id: 3)

      @n1 = FactoryGirl.create(:network_name, name: 'FriendShip', company_id: 0)

      NetworkSnapshotData.create(from_employee_id: e0.id, to_employee_id: e1.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e0.id, to_employee_id: e2.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e0.id, to_employee_id: e3.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e1.id, to_employee_id: e0.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e1.id, to_employee_id: e2.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e1.id, to_employee_id: e3.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e2.id, to_employee_id: e0.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e2.id, to_employee_id: e1.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e2.id, to_employee_id: e3.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e3.id, to_employee_id: e0.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e3.id, to_employee_id: e1.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e3.id, to_employee_id: e2.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e3.id, to_employee_id: e4.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e4.id, to_employee_id: e0.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e4.id, to_employee_id: e1.id, value: 1, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e4.id, to_employee_id: e2.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)
      NetworkSnapshotData.create(from_employee_id: e4.id, to_employee_id: e3.id, value: 0, snapshot_id: 1, network_id: @n1.id, company_id: 0)

      @pin = Pin.create(company_id: 0, name: 'testpin', definition: 'some def')
      EmployeesPin.create(pin_id: @pin.id, employee_id: e0.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e1.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e2.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e3.id)
    end

    after(:each) do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'for pin id1 ' do
      res = get_most_social_worker(@s.id, 1, 1)
      (res[0][:measure]).should eq(1)
      (res[1][:measure]).should eq(0.94)
      (res[2][:measure]).should eq(0.94)
      (res[3][:measure]).should eq(0.87)
    end

    it 'for group id2 ' do
      res = get_most_social_worker(@s.id, 1, -1, 2)
      (res[0][:measure]).should eq(1)
      (res[1][:measure]).should eq(1)
    end
  end

  describe 'test avg no. of attendees' do
    before do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.create!(id: 1, name: "Hevra10")
      Snapshot.create(id: 8, name: "2016-01", company_id: 1)
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Group.create!(id: 8, name: "R&R", company_id: 1, parent_group_id: 1, color_id: 9)
      Group.create!(id: 13, name: "D&D", company_id: 1, parent_group_id: 1, color_id: 8)
      Group.create!(id: 14, name: "AAA", company_id: 1, parent_group_id: 13, color_id: 8)
      Group.create!(id: 99, name: "NoMeetings", company_id: 1, parent_group_id: 1, color_id: 9)

      Employee.create!(id: 1, company_id: 1, group_id: 6, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi")
      Employee.create!(id: 2, company_id: 1, group_id: 6, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi")
      Employee.create!(id: 3, company_id: 1, group_id: 6, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi")
      Employee.create!(id: 5, company_id: 1, group_id: 13, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi")
      Employee.create!(id: 8, company_id: 1, group_id: 13, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi")
      Employee.create!(id: 13, company_id: 1, group_id: 13, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi")
      Employee.create!(id: 21, company_id: 1, group_id: 8, email: "bo@mail.com", external_id: "10023", first_name: "Bob", last_name: "Levi")
      Employee.create!(id: 34, company_id: 1, group_id: 99, email: "no@mail.com", external_id: "10093", first_name: "Lob", last_name: "Bevi")
      Employee.create!(id: 55, company_id: 1, group_id: 14, email: "bb@mail.com", external_id: "10903", first_name: "Bb", last_name: "Lvi")

      MeetingRoom.create!(name: 'room1', office_id: 1)
      MeetingRoom.create!(name: 'room2', office_id: 2)

      Meeting.create!(subject: 'testA', meeting_room_id: 1, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting1')
      Meeting.create!(subject: 'testA', meeting_room_id: 2, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting2')
      Meeting.create!(subject: 'testA', meeting_room_id: 3, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting3')
      Meeting.create!(subject: 'testB', meeting_room_id: 4, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting4')
      Meeting.create!(subject: 'testB', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting5')

      MeetingAttendee.create(meeting_id: 1, attendee_id: 1, attendee_type:0)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 2, attendee_type:0)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 8, attendee_type:0)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 13, attendee_type:0)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 55, attendee_type:0)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 1, attendee_type:0)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 2, attendee_type:0)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 3, attendee_type:0)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 8, attendee_type:0)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 13, attendee_type:0)
      MeetingAttendee.create(meeting_id: 3, attendee_id: 8, attendee_type:0)
      MeetingAttendee.create(meeting_id: 3, attendee_id: 13, attendee_type:0)
      MeetingAttendee.create(meeting_id: 3, attendee_id: 21, attendee_type:0)
    end

    it'Vanila test' do
      expect(AlgorithmsHelper.average_no_of_attendees(8, -1, 6)[0][:measure]).to be == 5.to_f / 2.to_f
    end

    it 'Check that adding an attendee to an already attended meeting increases the group\'s average' do
      x1 = AlgorithmsHelper.average_no_of_attendees(8, -1, 13)[0][:measure]
      MeetingAttendee.create(meeting_id: 3, attendee_id: 5, attendee_type:0)
      expect(AlgorithmsHelper.average_no_of_attendees(8, -1, 13)[0][:measure]).to be > x1
    end

    it 'Check that adding a meeting decreases the group\'s average' do
      x1 = AlgorithmsHelper.average_no_of_attendees(8, -1, 6)[0][:measure]
      MeetingAttendee.create(meeting_id: 4, attendee_id: 2, attendee_type:0)
      expect(AlgorithmsHelper.average_no_of_attendees(8, -1, 6)[0][:measure]).to be < x1
    end

    it'Check that a group with no meetings return 0' do
      expect(AlgorithmsHelper.average_no_of_attendees(8, -1, 99)[0][:measure]).to be == 0.to_f
    end
  end

  describe 'test Proportion time spent on meetings' do
    before do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.create!(id: 1, name: "Hevra10")
      Snapshot.create(id: 8, name: "2016-01", company_id: 1)
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Group.create!(id: 8, name: "R&R", company_id: 1, parent_group_id: 1, color_id: 9)
      Group.create!(id: 13, name: "D&D", company_id: 1, parent_group_id: 1, color_id: 8)
      Group.create!(id: 14, name: "AAA", company_id: 1, parent_group_id: 13, color_id: 8)
      Group.create!(id: 99, name: "NoMeetings", company_id: 1, parent_group_id: 1, color_id: 9)

      Employee.create!(id: 1, company_id: 1, group_id: 6, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi")
      Employee.create!(id: 2, company_id: 1, group_id: 6, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi")
      Employee.create!(id: 3, company_id: 1, group_id: 6, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi")
      Employee.create!(id: 5, company_id: 1, group_id: 13, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi")
      Employee.create!(id: 8, company_id: 1, group_id: 13, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi")
      Employee.create!(id: 13, company_id: 1, group_id: 13, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi")
      Employee.create!(id: 21, company_id: 1, group_id: 8, email: "bo@mail.com", external_id: "10023", first_name: "Bob", last_name: "Levi")
      Employee.create!(id: 34, company_id: 1, group_id: 99, email: "no@mail.com", external_id: "10093", first_name: "Lob", last_name: "Bevi")
      Employee.create!(id: 55, company_id: 1, group_id: 14, email: "bb@mail.com", external_id: "10903", first_name: "Bb", last_name: "Lvi")

      MeetingRoom.create!(name: 'room1', office_id: 1)
      MeetingRoom.create!(name: 'room2', office_id: 2)

      Meeting.create!(subject: 'testA', meeting_room_id: 1, snapshot_id: 8, duration_in_minutes: 120, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting1')
      Meeting.create!(subject: 'testB', meeting_room_id: 2, snapshot_id: 8, duration_in_minutes: 150, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting2')
      Meeting.create!(subject: 'testC', meeting_room_id: 3, snapshot_id: 8, duration_in_minutes: 30, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting3')
      Meeting.create!(subject: 'testD', meeting_room_id: 4, snapshot_id: 8, duration_in_minutes: 200, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting4')
      Meeting.create!(subject: 'testE', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 6, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting5')

      MeetingAttendee.create(meeting_id: 1, attendee_id: 1)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 2)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 8)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 13)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 55)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 1)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 2)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 3)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 8)
      MeetingAttendee.create(meeting_id: 2, attendee_id: 13)
      MeetingAttendee.create(meeting_id: 3, attendee_id: 8)
      MeetingAttendee.create(meeting_id: 3, attendee_id: 13)
      MeetingAttendee.create(meeting_id: 3, attendee_id: 21)
      MeetingAttendee.create(meeting_id: 4, attendee_id: 1)
      MeetingAttendee.create(meeting_id: 4, attendee_id: 8)
      MeetingAttendee.create(meeting_id: 4, attendee_id: 13)
      MeetingAttendee.create(meeting_id: 4, attendee_id: 21)
      MeetingAttendee.create(meeting_id: 5, attendee_id: 13)
      MeetingAttendee.create(meeting_id: 5, attendee_id: 21)
    end

    it'Check that a group with no meetings return 0' do
      expect(AlgorithmsHelper.proportion_time_spent_on_meetings(8, -1, 99)[0][:measure]).to be(0.0)
    end

    it'Check that a group with overtime meetings return 1' do
      Meeting.create!(subject: 'testF', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 3210, start_time: Time.now, company_id: 1, meeting_uniq_id: 'test meeting overtime')
      Group.create!(id: 100, name: "EndlessMeetings", company_id: 1, color_id: 9)
      Employee.create!(id: 100, company_id: 1, group_id: 100, email: "ovt@mail.com", external_id: "11003", first_name: "Over", last_name: "Time")
      MeetingAttendee.create(meeting_id: 6, attendee_id: 100, attendee_type:0)
      expect(AlgorithmsHelper.proportion_time_spent_on_meetings(8, -1, 100)[0][:measure]).to be(1.0)
    end

    it 'Check that adding a meeting to a group member decreases the group\'s score' do
      x1 = AlgorithmsHelper.proportion_time_spent_on_meetings(8, -1, 6)[0][:measure]
      MeetingAttendee.create(meeting_id: 3, attendee_id: 2, attendee_type:0)
      expect(AlgorithmsHelper.proportion_time_spent_on_meetings(8, -1, 6)[0][:measure]).to be > x1
    end

    it 'Check that adding a new member (with no meetings) to a group increases the group\'s score' do
      x1 = AlgorithmsHelper.proportion_time_spent_on_meetings(8, -1, 13)[0][:measure]
      Employee.create!(id: 9999, company_id: 1, group_id: 13, email: "com@mail.com", external_id: "10793", first_name: "LoL", last_name: "Nevi")
      expect(AlgorithmsHelper.proportion_time_spent_on_meetings(8, -1, 13)[0][:measure]).to be < x1
    end
  end

  describe 'test no of emails' do
    describe 'number of emails' do
      before do
        NetworkSnapshotData.delete_all
        Employee.delete_all
        Group.delete_all
        Company.delete_all
        NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
        Company.find_or_create_by(id: 1, name: "Hevra10")
        Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
        Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
        Employee.find_or_create_by(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
        Employee.find_or_create_by(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
        Employee.find_or_create_by(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
        Employee.find_or_create_by(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
        Employee.find_or_create_by(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
        Employee.find_or_create_by(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 4,  snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 11, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 15, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 11, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, n1: 3)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, n1: 3)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4,  snapshot_id: 1, n1: 3)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, n1: 3)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4,  snapshot_id: 1, n1: 2)
      end
      it 'sent standard' do
        expect(AlgorithmsHelper.no_of_emails_sent(1, -1, 6)[0][:measure]).to be == 1.to_f / 6.to_f
      end

      it 'sent standard' do
        NetworkSnapshotData.last.delete
        NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4,  snapshot_id: 1, n1: 2, n11: 100)
        expect(AlgorithmsHelper.no_of_emails_sent(1, -1, 6)[0][:measure]).to be == 1.to_f / 6.to_f
      end
    end

    it 'sent explore standard' do
      NetworkSnapshotData.delete_all
      Employee.delete_all
      Group.delete_all
      Company.delete_all
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Employee.find_or_create_by(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 0, n2: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 0, n2: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      res = AlgorithmsHelper.no_of_emails_sent_for_explore(1, -1, 6)
      elem = res.select { |r| r[:id] == 11 }
      expect(elem.first[:measure]).to eq(1)
    end

    it 'received standard' do
      NetworkSnapshotData.delete_all
      Employee.delete_all
      Group.delete_all
      Company.delete_all
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Employee.find_or_create_by(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 0, n2: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, n2: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      expect(AlgorithmsHelper.no_of_emails_received(1, -1, 6)[0][:measure]).to be == 1.to_f / 6.to_f
    end

    it 'received explore standard' do
      NetworkSnapshotData.delete_all
      Employee.delete_all
      Group.delete_all
      Company.delete_all
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Employee.find_or_create_by(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 0, n2: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, n2: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      res = AlgorithmsHelper.no_of_emails_received_for_explore(1, -1, 6)
      elem = res.select { |r| r[:id] == 0 }
      expect( elem.first[:measure] ).to eq(1)
    end
  end

  describe 'sinks flag' do
    it 'when one is in the higher quartile but not above median+iqr*1.5' do
      NetworkSnapshotData.delete_all
      Employee.delete_all
      Group.delete_all
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Employee.find_or_create_by(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 16, company_id: 1, email: "ger4@mail.com", external_id: "10043", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 17, company_id: 1, email: "ger7@mail.com", external_id: "10033", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 4, n2: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 4, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 4)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 4)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 4)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 4)
      expect(AlgorithmsHelper.flag_sinks(1, -1, 6)[0][:measure]).to be == 0.to_f
    end
  end

  describe 'no of isolates' do
    it 'one empty emp' do
      NetworkSnapshotData.delete_all
      Employee.delete_all
      Group.delete_all
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Employee.find_or_create_by(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 0, n2: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 4, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      expect(AlgorithmsHelper.no_of_isolates(1, -1, 6)[0][:measure]).to be == (1.to_f/6.to_f) 
    end
  end

  describe 'volume of emails' do
    before do
      NetworkSnapshotData.delete_all
      Employee.delete_all
      Group.delete_all
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Employee.find_or_create_by(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1,  n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1,  n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, n1: 2, significant_level: :meaningfull)
    end

    it 'test base algorithm' do
      expect(AlgorithmsHelper.volume_of_emails(1, -1, 6)[0][:measure]).to be == 14.to_f
    end

    it 'with traffic not only in n1' do
      NetworkSnapshotData.last.delete
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, n1: 2, n7: 1, significant_level: :meaningfull)
      expect(AlgorithmsHelper.volume_of_emails(1, -1, 6)[0][:measure]).to be > 14.to_f
    end
  end

  describe 'test proportion of emails' do
    it 'test proportion' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra100")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n10:1, significant_level: :meaningfull)
      expect(AlgorithmsHelper.proportion_of_emails(1, -1, 6)[0][:measure]).to be == 0.5
    end

    it 'test proportion on empty n10' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra100")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, significant_level: :meaningfull)
      expect(AlgorithmsHelper.proportion_of_emails(1, -1, 6)[0][:measure]).to be == 1.0
    end

    it 'test proportion on empty n1' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra100")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n10: 1, significant_level: :meaningfull)
      expect(AlgorithmsHelper.proportion_of_emails(1, -1, 6)[0][:measure]).to be == 0.0
    end

    it 'test proportion on empty n1' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra100")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      expect(AlgorithmsHelper.proportion_of_emails(1, -1, 6)[0][:measure]).to be == 0.0
    end
  end

  ######################################### tests for advise ####################################

  describe 'network density' do
    it 'regular' do
      DatabaseCleaner.clean_with(:truncation)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)

      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      NetworkName.create!(id: 2, name: 'Friendship', company_id: 1)
      NetworkName.create!(id: 3, name: 'Trust', company_id: 1)
      [[13,15],[13,21],[15,13],[15,21], [15,11],[15,14],[21,11],[11,15],[11,21],[11,4],[14,13],[14,11],[14,15],[14,4],[4,13],[4,15],[4,14]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[13,15],[13,21],[4,15],[21,11],[11,15],[11,21],[4,14],[15,21],[15,11],[13,14],[4,13],[14,13],[14,11],[14,21],[11,4],[14,4]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      expect(AlgorithmsHelper.density_of_network(1, 6, -1, 2, 3)[0][:measure]).to be == 0.778
    end
  end

  ############################################## FLAGS HELPER tests ################################
  
  describe 'most promising flag' do
    before(:each) do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 0)
      e = []
      (0..24).each do |index|
        e[index] = FactoryGirl.create(:employee, email: "a#{index}@b.com", group_id: 3)
      end

      (0..24).to_a.permutation(2).to_a.each do |pair|
        @nw1 = NetworkName.create!(id: 2, name: 'Friendship', company_id: 0)
        @nw2 = NetworkName.create!(id: 3, name: 'Advice', company_id: 0)

        NetworkSnapshotData.create(to_employee_id: e[pair[0]].id, from_employee_id: e[pair[1]].id, value: rand(2), snapshot_id: 1, network_id: @nw1.id, company_id: 0)
        NetworkSnapshotData.create(to_employee_id: e[pair[0]].id, from_employee_id: e[pair[1]].id, value: rand(2), snapshot_id: 1, network_id: @nw2.id, company_id: 0)
      end

      @pin2 = Pin.create(company_id: 1, name: 'testpin2', definition: 'some def2')
      (0..14).each do |index|
        EmployeesPin.create(pin_id: @pin2.id, employee_id: e[index].id)
      end
    end

    xit 'for company, most promising emps should have better measures than their peers in social and advisor measures' do
      advisors = CdsSelectionHelper.format_from_activerecord_result(get_list_of_employees_in(@recent_snapshot, @nw2.id))
      most_social = get_most_social_worker(@recent_snapshot, @nw2.id)
      most_promising_arr = most_promising_worker(1, @recent_snapshot, @nw2.id, @nw1.id)
      expected_size = [10, get_unit_size(1, -1, -1)].min
      # ###################difference in size between candidate group and entire group ###############
      diff1 = (most_social.length - expected_size)
      diff2 = (advisors.length - expected_size)
      # #get all measure values for each measure contributing to flag ################################
      all_advisors_values = advisors.map { |elem| elem[:measure].to_i }
      all_social_values = most_social.map { |elem| elem[:measure] }
      all_promising_in_social_values = []
      all_promising_in_advisor_values = []
      # ###################get  measure values of all candiadates ####################################
      most_promising_arr.each do |looked|
        advisors.map { |entry| all_promising_in_advisor_values.push(entry[:measure].to_i) if looked[:id] == entry[:id] }
        most_social.map { |entry| all_promising_in_social_values.push(entry[:measure]) if looked[:id] == entry[:id] }
      end
      # ############test for each promising talent that their value is larger than at least the difference in size between promising group and the entire group#
      all_promising_in_advisor_values.each do |val|
        res1 = all_advisors_values.count { |x| x <= val }
        expect(res1).to be >= diff2
      end
      all_promising_in_social_values.each do |val|
        res2 = all_social_values.count { |x| x <= val }
        expect(res2).to be >= diff1
      end
      expect(most_promising_arr.length).to be <= expected_size
    end

    xit 'for pin with id 2, most promising emps should have better measures than their peers in social and advisor measures' do
      advisors = CdsSelectionHelper.format_from_activerecord_result(get_list_of_employees_in(@recent_snapshot, @nw2.id, @pin2.id, -1))
      most_social = get_most_social_worker(@recent_snapshot, @nw1.id, @pin2.id, -1)
      most_promising_arr = most_promising_worker(1, @recent_snapshot, @pin2.id, -1)
      expected_size = [10, get_unit_size(1, @pin2.id, -1)].min
      # ###################difference in size between candidate group and entire group ###############
      diff1 = (most_social.length - expected_size)
      diff2 = (advisors.length - expected_size)
      # #get all measure values for each measure contributing to flag ################################
      all_advisors_values = advisors.map { |elem| elem[:measure].to_i }
      all_social_values = most_social.map { |elem| elem[:measure] }
      all_promising_in_social_values = []
      all_promising_in_advisor_values = []
      # ###################get  measure values of all candiadates ####################################
      most_promising_arr.each do |looked|
        advisors.map { |entry| all_promising_in_advisor_values.push(entry[:measure].to_i) if looked[:id] == entry[:id] }
        most_social.map { |entry| all_promising_in_social_values.push(entry[:measure]) if looked[:id] == entry[:id] }
      end
      # ############test for each promising talent that their value is larger than at least the difference in size between promising group and the entire group#
      all_promising_in_advisor_values.each do |val|
        res1 = all_advisors_values.count { |x| x <= val }
        expect(res1).to be >= diff2
      end
      all_promising_in_social_values.each do |val|
        res2 = all_social_values.count { |x| x <= val }
        expect(res2).to be >= diff1
      end
      expect(most_promising_arr.length).to be <= expected_size
      # puts most_promising_arr
    end
  end

  describe 'subject length' do
    before(:each) do
      DatabaseCleaner.clean_with(:truncation)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: 'Hevra10')
      Snapshot.find_or_create_by(id: 1, name: '2016-01', company_id: 1)
      Group.find_or_create_by(id: 6, name: 'R&D', company_id: 1, parent_group_id: 1, color_id: 10)
      Employee.find_or_create_by(id: 13, company_id: 1, email: 'gar@mail.com', external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 15, company_id: 1, email: 'hal@mail.com', external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 21, company_id: 1, email: 'ken@mail.com', external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 11, company_id: 1, email: 'fra@mail.com', external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 4, company_id: 1, email: 'bob@mail.com', external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.find_or_create_by(id: 14, company_id: 1, email: 'ger@mail.com', external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
    end
    it 'avg on subject' do
      EmailSubjectSnapshotData.create!(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, subject: 'Lo Harbe milim')
      EmailSubjectSnapshotData.create!(employee_from_id: 21, employee_to_id: 15, snapshot_id: 1, subject: 'Lo Harbe milim23')
      EmailSubjectSnapshotData.create!(employee_from_id: 14, employee_to_id: 15, snapshot_id: 1, subject: 'Lo Harbe milim23')
      EmailSubjectSnapshotData.create!(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, subject: 'Harbe meod meod ')
      EmailSubjectSnapshotData.create!(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, subject: 'Harbe meod meod meod meod meod meod meod milim a lot of words')
      expect(AlgorithmsHelper.avg_subject_length(1, -1, 6)[0][:measure]).to be == 1.to_f / 6.to_f
    end
    it 'avg on subject on too few' do
      EmailSubjectSnapshotData.create!(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, subject: 'Harbe meod meod ')
      EmailSubjectSnapshotData.create!(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, subject: 'Harbe meod meod meod meod meod meod meod milim a lot of words')
      expect(AlgorithmsHelper.avg_subject_length(1, -1, 6)[0][:measure]).to be == 0.0
    end
  end

  describe 'assign_same_score_to_all_emps' do
    sid = -1
    before(:each) do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 0)
      sid = snapshot_factory_create({company_id: 1, timestamp: Time.zone.now, name: 'testshot'})
      emp1
      emp2
    end

    it 'should return all emps in company if no group and pin is given' do
      res = AlgorithmsHelper.assign_same_score_to_all_emps(sid)
      expect(res.length).to eq(2)
    end

    it 'should return all emps in group' do
      gr = Group.create(id: 10, company_id: 1, name: 'testgroup')
      emp1.update(group_id: gr.id)
      res = AlgorithmsHelper.assign_same_score_to_all_emps(sid, gr.id)
      expect(res.length).to eq(1)
    end

    it 'should assign 1 to all emps' do
      res = AlgorithmsHelper.assign_same_score_to_all_emps(sid)
      expect(res.select { |r| r[:measure] == 1 }.size).to eq(2)
    end
  end
end
