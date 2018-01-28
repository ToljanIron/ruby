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

      MeetingAttendee.create(meeting_id: 1, employee_id: 1)
      MeetingAttendee.create(meeting_id: 1, employee_id: 2)
      MeetingAttendee.create(meeting_id: 1, employee_id: 8)
      MeetingAttendee.create(meeting_id: 1, employee_id: 13)
      MeetingAttendee.create(meeting_id: 1, employee_id: 55)
      MeetingAttendee.create(meeting_id: 2, employee_id: 1)
      MeetingAttendee.create(meeting_id: 2, employee_id: 2)
      MeetingAttendee.create(meeting_id: 2, employee_id: 3)
      MeetingAttendee.create(meeting_id: 2, employee_id: 8)
      MeetingAttendee.create(meeting_id: 2, employee_id: 13)
      MeetingAttendee.create(meeting_id: 3, employee_id: 8)
      MeetingAttendee.create(meeting_id: 3, employee_id: 13)
      MeetingAttendee.create(meeting_id: 3, employee_id: 21)
    end

    xit 'Vanila test' do
      expect(AlgorithmsHelper.average_no_of_attendees(8, -1, 6)[0][:measure]).to be == 5.to_f / 2.to_f
    end

    xit 'Check that adding an attendee to an already attended meeting increases the group\'s average' do
      x1 = AlgorithmsHelper.average_no_of_attendees(8, -1, 13)[0][:measure]
      MeetingAttendee.create(meeting_id: 3, attendee_id: 5)
      expect(AlgorithmsHelper.average_no_of_attendees(8, -1, 13)[0][:measure]).to be > x1
    end

    xit 'Check that adding a meeting decreases the group\'s average' do
      x1 = AlgorithmsHelper.average_no_of_attendees(8, -1, 6)[0][:measure]
      MeetingAttendee.create(meeting_id: 4, attendee_id: 2)
      expect(AlgorithmsHelper.average_no_of_attendees(8, -1, 6)[0][:measure]).to be < x1
    end

    xit'Check that a group with no meetings return 0' do
      expect(AlgorithmsHelper.average_no_of_attendees(8, -1, 99)[0][:measure]).to be == 0.to_f
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
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 4,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 15, employee_to_id: 4,  snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 15, employee_to_id: 11, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, n1: 0)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 21, employee_to_id: 15, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 21, employee_to_id: 11, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 21, employee_to_id: 4,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, n1: 3)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, n1: 3)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 11, employee_to_id: 4,  snapshot_id: 1, n1: 3)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, n1: 3)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 4, employee_to_id: 13,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 4, employee_to_id: 15,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 4, employee_to_id: 11,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 4, employee_to_id: 14,  snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, n1: 2)
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 14, employee_to_id: 4,  snapshot_id: 1, n1: 2)
      end
      it 'sent standard' do
        expect(AlgorithmsHelper.no_of_emails_sent(1, -1, 6)[0][:measure]).to be == 1.to_f / 6.to_f
      end

      it 'sent standard' do
        NetworkSnapshotData.last.delete
        NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 14, employee_to_id: 4,  snapshot_id: 1, n1: 2, n11: 100)
        expect(AlgorithmsHelper.no_of_emails_sent(1, -1, 6)[0][:measure]).to be == 1.to_f / 6.to_f
      end
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

      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 0, n2: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 4, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 15, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 11, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 4, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(company_id: 1, employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 2, significant_level: :meaningfull)
      expect(AlgorithmsHelper.no_of_isolates(1, -1, 6)[0][:measure]).to be == (1.to_f/6.to_f) 
    end
  end
end
