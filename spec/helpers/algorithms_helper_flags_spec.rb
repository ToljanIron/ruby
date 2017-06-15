# frozen_string_literal: true
require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryGirl::Syntax::Methods

describe AlgorithmsHelper, type: :helper do
  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'test information isolate ' do
    before(:each) do
      NetworkName.find_or_create_by!(id: 2, name: "Communication Flow", company_id: 2)
      Company.create!(id: 2, name: 'testcom', randomize_image: true, active: true)
      snapshot_factory_create(id: 45, name: '2015-06', snapshot_type: 3, company_id: 2)
      Group.create!(id: 28, name: 'CS', company_id: 2, parent_group_id: nil)
      Employee.create!(id: 1, company_id: 2, email: 'pete1@sala.com', external_id: '11', first_name: 'Dave1', last_name: 'sala', group_id: 28)
      Employee.create!(id: 2, company_id: 2, email: 'pete2@sala.com', external_id: '12', first_name: 'Dave2', last_name: 'sala', group_id: 28)
      Employee.create!(id: 3, company_id: 2, email: 'pete3@sala.com', external_id: '13', first_name: 'Dave3', last_name: 'sala', group_id: 28)
      Employee.create!(id: 4, company_id: 2, email: 'pete4@sala.com', external_id: '14', first_name: 'Dave4', last_name: 'sala', group_id: 28)
      Employee.create!(id: 5, company_id: 2, email: 'pete5@sala.com', external_id: '15', first_name: 'Dave5', last_name: 'sala', group_id: 28)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 2)
    end

    it 'emp 2 should be an information isolate' do
      Employee.create!(id: 6, company_id: 2, email: 'pete6@sala.com', external_id: '16', first_name: 'Dave6', last_name: 'sala', group_id: 28)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 2, employee_to_id: 4, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 2, employee_to_id: 1, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 3, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 4, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 5, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 6, snapshot_id: 45, n1: 1, company_id: 2)

      wer = AlgorithmsHelper.calculate_information_isolate(45, 1, -1, 28)
      expect(wer.include?(id: 2, measure: 1)).to eq(true)
    end

    it 'no one is an information isolate' do
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 2, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 2, employee_to_id: 3, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 4, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 1, snapshot_id: 45, n1: 1, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 5, snapshot_id: 45, n1: 1, company_id: 2)

      wer = AlgorithmsHelper.calculate_information_isolate(45, 1, -1, 28)
      expect(wer.count).to eq(0)
    end

    it 'email factor does not change result' do
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 2, snapshot_id: 45, n1: 10, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 2, employee_to_id: 3, snapshot_id: 45, n1: 10, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 4, snapshot_id: 45, n1: 10, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 1, snapshot_id: 45, n1: 10, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 5, snapshot_id: 45, n1: 10, company_id: 2)

      wer = AlgorithmsHelper.calculate_information_isolate(45, 1, -1, 28)
      expect(wer.count).to eq(0)
    end

    it 'emp 4 has less emails, but by little, so still is an information isolate' do
      Employee.create!(id: 6, company_id: 2, email: 'pete6@sala.com', external_id: '16', first_name: 'Dave6', last_name: 'sala', group_id: 28)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 2, snapshot_id: 45, n1: 3, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 2, employee_to_id: 3, snapshot_id: 45, n1: 3, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 4, snapshot_id: 45, n1: 2, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 5, snapshot_id: 45, n1: 3, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 1, snapshot_id: 45, n1: 3, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 6, snapshot_id: 45, n1: 3, company_id: 2)

      wer = AlgorithmsHelper.calculate_information_isolate(45, 1, -1, 28)
      expect(wer.include?(id: 4, measure: 1)).to be(true)
    end

    it 'emp 4 has more emails by much but should not be an information isolate' do
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 2, snapshot_id: 45, n1: 3, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 2, employee_to_id: 3, snapshot_id: 45, n1: 3, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 4, snapshot_id: 45, n1: 3, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 1, snapshot_id: 45, n1: 3, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 4, snapshot_id: 45, n1: 22, company_id: 2)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 1, snapshot_id: 45, n1: 3, company_id: 2)

      res = -1
      expect { res = AlgorithmsHelper.calculate_information_isolate(45, 1, -1, 28) }.not_to raise_error
      expect(res.include?(id: 4, measure: 1)).to be(false)
    end
  end

  describe 'Test powerful non managers' do
    before(:each) do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 2)
      Company.create!(id: 2, name: 'testcom', randomize_image: true, active: true)
      snapshot_factory_create(id: 45, name: '2015-06', snapshot_type: 3, company_id: 2)
      Group.create!(id: 28, name: 'CS', company_id: 2, parent_group_id: nil)
      Employee.create!(id: 1, company_id: 2, email: 'pete@sala.com', external_id: '14', first_name: 'Dave', last_name: 'sala', date_of_birth: '1999-12-31 22:00:00', employment: nil, gender: 0, group_id: 28, home_address: '', job_title_id: 644, marital_status_id: nil, middle_name: '', position_scope: nil, qualifications: nil, office_id: 25, work_start_date: '2013-04-18 21:00:00', img_url_last_updated: '2016-03-06 08:01:23', age_group_id: nil, seniority_id: nil, formal_level: nil)
      Employee.create!(id: 2, company_id: 2, email: 'frank@sala.com', external_id: '15', first_name: 'Dave1', last_name: 'sala', date_of_birth: '1999-12-31 22:00:00', employment: nil, gender: 0, group_id: 28, home_address: '', job_title_id: 644, marital_status_id: nil, middle_name: '', position_scope: nil, qualifications: nil, office_id: 25, work_start_date: '2013-04-18 21:00:00', img_url_last_updated: '2016-03-06 08:01:23', age_group_id: nil, seniority_id: nil, formal_level: nil)
      Employee.create!(id: 3, company_id: 2, email: 'bill@sala.com', external_id: '16', first_name: 'Dave2', last_name: 'sala', date_of_birth: '1999-12-31 22:00:00', employment: nil, gender: 0, group_id: 28, home_address: '', job_title_id: 644, marital_status_id: nil, middle_name: '', position_scope: nil, qualifications: nil, office_id: 25, work_start_date: '2013-04-18 21:00:00', img_url_last_updated: '2016-03-06 08:01:23', age_group_id: nil, seniority_id: nil, formal_level: nil)
      Employee.create!(id: 4, company_id: 2, email: 'da@sala.com', external_id: '17', first_name: 'Dave3', last_name: 'sala', date_of_birth: '1999-12-31 22:00:00', employment: nil, gender: 0, group_id: 28, home_address: '', job_title_id: 644, marital_status_id: nil, middle_name: '', position_scope: nil, qualifications: nil, office_id: 25, work_start_date: '2013-04-18 21:00:00', img_url_last_updated: '2016-03-06 08:01:23', age_group_id: nil, seniority_id: nil, formal_level: nil)
      Employee.create!(id: 5, company_id: 2, email: 'dar@sala.com', external_id: '18', first_name: 'Dave4', last_name: 'sala', date_of_birth: '1999-12-31 22:00:00', employment: nil, gender: 0, group_id: 28, home_address: '', job_title_id: 644, marital_status_id: nil, middle_name: '', position_scope: nil, qualifications: nil, office_id: 25, work_start_date: '2013-04-18 21:00:00', img_url_last_updated: '2016-03-06 08:01:23', age_group_id: nil, seniority_id: nil, formal_level: nil)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 2)
      NetworkName.create!(id: 2, name: 'Trust', company_id: 2)
      NetworkName.create!(id: 3, name: 'Friendship', company_id: 2)
    end

    it 'employees 2 and 3 should be powerful non managers' do
      NetworkSnapshotData.delete_all
      (0..4).each do |ids|
        NetworkSnapshotData.create_email_adapter(employee_from_id: ids + 1, employee_to_id: 2, snapshot_id: 45, n1: 0, n2: 0, n3: 0, n4: 2, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
        NetworkSnapshotData.create_email_adapter(employee_from_id: ids + 1, employee_to_id: 3, snapshot_id: 45, n1: 0, n2: 0, n3: 0, n4: 2, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      end

      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: 1, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: 3, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: 4, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: 4, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: 3, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: 2, to_employee_id: 3, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 1, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 3, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 4, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 4, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 3, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 2, to_employee_id: 3, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 1, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 3, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 4, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 4, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 3, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 2, to_employee_id: 3, value: 1)
      res = AlgorithmsHelper.calculate_powerful_non_managers(45, 1, 2, 3, -1, 28)
      expect(res.length).to eq(2)
      expect(res).to include(id: 3, measure: 1.0)
    end

    it 'employees 4 should be powerful non managers' do
      NetworkSnapshotData.delete_all
      (0..4).each do |ids|
        NetworkSnapshotData.create_email_adapter(employee_from_id: ids + 1, employee_to_id: 4, snapshot_id: 45, n1: 0, n2: 0, n3: 0, n4: 2, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      end

      [1, 2, 3, 5].each do |i|
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: i, to_employee_id: 4, value: 1)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: i, to_employee_id: 4, value: 1)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: i, to_employee_id: 4, value: 1)
      end

      res = AlgorithmsHelper.calculate_powerful_non_managers(45, 1, 2, 3, -1, 28)
      expect(res.length).to eq(1)
      expect(res).to include(id: 4, measure: 1.0)
    end

    it 'when emp 6 becomes a manager he should not be a powerful non-manager' do
      Employee.create!(id: 6, company_id: 2, email: 'manager@sala.com', external_id: '18', first_name: 'Dave6', last_name: 'sala6', group_id: 28)
      NetworkSnapshotData.delete_all
      (0..4).each do |ids|
        NetworkSnapshotData.create_email_adapter(employee_from_id: ids + 1, employee_to_id: 4, snapshot_id: 45, n1: 0, n2: 0, n3: 0, n4: 2, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
        NetworkSnapshotData.create_email_adapter(employee_from_id: ids + 1, employee_to_id: 6, snapshot_id: 45, n1: 0, n2: 0, n3: 0, n4: 2, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      end

      [1, 2, 3, 5].each do |i|
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: i, to_employee_id: 4, value: 1)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: i, to_employee_id: 4, value: 1)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: i, to_employee_id: 4, value: 1)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: i, to_employee_id: 6, value: 1)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: i, to_employee_id: 6, value: 1)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: i, to_employee_id: 6, value: 1)
      end

      ## emp 6 is not a manager now
      res = AlgorithmsHelper.calculate_powerful_non_managers(45, 1, 2, 3, -1, 28)
      expect(res.length).to eq(2)
      expect(res).to include(id: 6, measure: 1.0)
      expect(res).to include(id: 4, measure: 1.0)

      ## now emp 6 becomes a manager
      EmployeeManagementRelation.create!(manager_id: 6, employee_id: 3, relation_type: 1)
      res = AlgorithmsHelper.calculate_powerful_non_managers(45, 1, 2, 3, -1, 28)
      expect(res).to include(id: 4, measure: 1.0)
      expect(res.length).to eq(1)
    end

    it 'powerful non manager should work without one of the networks' do
      NetworkSnapshotData.delete_all
      [1, 2, 3, 5].each do |i|
        NetworkSnapshotData.create_email_adapter(employee_from_id: i, employee_to_id: 4, snapshot_id: 45, n1: 0, n2: 0, n3: 0, n4: 2, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0, n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 2, from_employee_id: i, to_employee_id: 4, value: 1)
        NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: i, to_employee_id: 4, value: 1)
      end

      res = AlgorithmsHelper.calculate_powerful_non_managers(45, 1, 2, 3, -1, 28)
      expect(res.include?(id: 4, measure: 1)).to be(true)
    end

    it 'powerful non manager without email traffic' do
      NetworkSnapshotData.delete_all
      expect { AlgorithmsHelper.calculate_powerful_non_managers(45, 1, 2, 3, -1, 28) }.to_not raise_error
    end
  end

  describe 'Test proportion of managers never in meetings' do
    before(:each) do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 2)
      Company.create!(id: 2, name: 'testcom', randomize_image: true, active: true)
      snapshot_factory_create(id: 8, name: '2015-06', snapshot_type: 3, company_id: 2)
      Group.create!(id: 6,  name: 'CS',         company_id: 2, parent_group_id: nil)
      Group.create!(id: 8,  name: 'SC',         company_id: 2, parent_group_id: nil)
      Group.create!(id: 13, name: 'D&D',        company_id: 2, parent_group_id: 8,  color_id: 7)
      Group.create!(id: 14, name: 'AAA',        company_id: 2, parent_group_id: 13, color_id: 8)
      Group.create!(id: 99, name: 'NoMeetings', company_id: 2, parent_group_id: 6,  color_id: 9)
      Employee.create!(id: 1,   company_id: 2, group_id: 6,   email: 'bob@mail.com',  external_id: '10003', first_name: 'Bob', last_name: 'Levi')
      Employee.create!(id: 2,   company_id: 2, group_id: 6,   email: 'fra@mail.com',  external_id: '10010', first_name: 'Fra', last_name: 'Levi')
      Employee.create!(id: 3,   company_id: 2, group_id: 6,   email: 'gar@mail.com',  external_id: '10012', first_name: 'Gar', last_name: 'Levi')
      Employee.create!(id: 5,   company_id: 2, group_id: 6,   email: 'ger@mail.com',  external_id: '10013', first_name: 'Ger', last_name: 'Levi')
      Employee.create!(id: 8,   company_id: 2, group_id: 13,  email: 'hal@mail.com',  external_id: '10014', first_name: 'Hal', last_name: 'Levi')
      Employee.create!(id: 13,  company_id: 2, group_id: 13,  email: 'ken@mail.com',  external_id: '10020', first_name: 'Ken', last_name: 'Levi')
      Employee.create!(id: 21,  company_id: 2, group_id: 13,  email: 'bo@mail.com',   external_id: '10023', first_name: 'Bob', last_name: 'Levi')
      Employee.create!(id: 34,  company_id: 2, group_id: 13,  email: 'no@mail.com',   external_id: '10093', first_name: 'Lob', last_name: 'Bevi')
      Employee.create!(id: 55,  company_id: 2, group_id: 13,  email: 'bb@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 89,  company_id: 2, group_id: 13,  email: 'dd@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 144,  company_id: 2, group_id: 14,  email: 'yd@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 101,  company_id: 2, group_id: 14,  email: 'ed@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 102,  company_id: 2, group_id: 14,  email: 'fd@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 103,  company_id: 2, group_id: 14,  email: 'gd@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 104,  company_id: 2, group_id: 14,  email: 'hd@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 105,  company_id: 2, group_id: 14,  email: 'id@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 106,  company_id: 2, group_id: 14,  email: 'jd@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 107,  company_id: 2, group_id: 14,  email: 'kd@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 108,  company_id: 2, group_id: 14,  email: 'ld@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 109,  company_id: 2, group_id: 14,  email: 'md@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      Employee.create!(id: 110,  company_id: 2, group_id: 14,  email: 'nd@mail.com',   external_id: '10903', first_name: 'Bb',  last_name: 'Lvi')
      EmployeeManagementRelation.create(manager_id: 1, employee_id: 3, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 2, employee_id: 3, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 2, employee_id: 5, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 13, employee_id: 8, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 13, employee_id: 21, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 13, employee_id: 34, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 8, employee_id: 55, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 21, employee_id: 89, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 101, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 102, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 103, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 104, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 105, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 106, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 107, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 108, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 109, employee_id: 144, relation_type: 2)
      EmployeeManagementRelation.create(manager_id: 110, employee_id: 144, relation_type: 2)
      MeetingRoom.create!(name: 'room1', office_id: 1)
      MeetingRoom.create!(name: 'room2', office_id: 2)
      Meeting.create!(subject: 'testA', meeting_room_id: 1, snapshot_id: 8, duration_in_minutes: 10, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting1')
      Meeting.create!(subject: 'testB', meeting_room_id: 2, snapshot_id: 8, duration_in_minutes: 20, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting2')
      Meeting.create!(subject: 'testC', meeting_room_id: 3, snapshot_id: 8, duration_in_minutes: 40, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting3')
      Meeting.create!(subject: 'testD', meeting_room_id: 4, snapshot_id: 8, duration_in_minutes: 80, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting4')
      Meeting.create!(subject: 'testE', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 16, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      Meeting.create!(subject: 'testF', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 32, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      Meeting.create!(subject: 'testG', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 64, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      Meeting.create!(subject: 'testH', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 128, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      Meeting.create!(subject: 'testI', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 256, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      Meeting.create!(subject: 'testJ', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 666, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      Meeting.create!(subject: 'testK', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 60, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      Meeting.create!(subject: 'testL', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 420, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      Meeting.create!(subject: 'testM', meeting_room_id: 5, snapshot_id: 8, duration_in_minutes: 19, start_time: Time.zone.now, company_id: 1, meeting_uniq_id: 'test meeting5')
      MeetingAttendee.create(meeting_id: 1,  attendee_id: 1)
      MeetingAttendee.create(meeting_id: 1,  attendee_id: 2)
      MeetingAttendee.create(meeting_id: 1,  attendee_id: 3)
      MeetingAttendee.create(meeting_id: 2,  attendee_id: 2)
      MeetingAttendee.create(meeting_id: 2,  attendee_id: 5)
      MeetingAttendee.create(meeting_id: 3,  attendee_id: 1)
      MeetingAttendee.create(meeting_id: 3,  attendee_id: 3)
      MeetingAttendee.create(meeting_id: 3,  attendee_id: 5)
      MeetingAttendee.create(meeting_id: 4,  attendee_id: 1)
      MeetingAttendee.create(meeting_id: 4,  attendee_id: 5)
      MeetingAttendee.create(meeting_id: 5,  attendee_id: 5)
      MeetingAttendee.create(meeting_id: 6,  attendee_id: 13)
      MeetingAttendee.create(meeting_id: 6,  attendee_id: 21)
      MeetingAttendee.create(meeting_id: 6,  attendee_id: 89)
      MeetingAttendee.create(meeting_id: 7,  attendee_id: 13)
      MeetingAttendee.create(meeting_id: 7,  attendee_id: 21)
      MeetingAttendee.create(meeting_id: 8,  attendee_id: 13)
      MeetingAttendee.create(meeting_id: 8,  attendee_id: 21)
      MeetingAttendee.create(meeting_id: 8,  attendee_id: 55)
      MeetingAttendee.create(meeting_id: 9,  attendee_id: 13)
      MeetingAttendee.create(meeting_id: 9,  attendee_id: 21)
      MeetingAttendee.create(meeting_id: 9,  attendee_id: 34)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 13)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 21)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 13)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 21)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 13)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 34)
      MeetingAttendee.create(meeting_id: 13, attendee_id: 55)
      MeetingAttendee.create(meeting_id: 13, attendee_id: 8)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 101)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 102)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 103)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 104)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 105)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 106)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 107)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 109)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 101)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 102)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 103)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 104)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 105)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 106)
      MeetingAttendee.create(meeting_id: 11, attendee_id: 107)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 109)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 107)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 106)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 101)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 102)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 103)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 104)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 105)
      MeetingAttendee.create(meeting_id: 9, attendee_id: 101)
      MeetingAttendee.create(meeting_id: 9, attendee_id: 103)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 101)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 110)
      MeetingAttendee.create(meeting_id: 1, attendee_id: 108)
    end

    it 'attending new meetings should get manager unflagged' do
      allow(AlgorithmsHelper).to receive(:is_less_than_100_emps).and_return(false)
      x1 = AlgorithmsHelper.proportion_of_managers_never_in_meetings(8, -1, 13)
      MeetingAttendee.create(meeting_id: 10, attendee_id: 108)
      MeetingAttendee.create(meeting_id: 12, attendee_id: 108)
      expect((AlgorithmsHelper.proportion_of_managers_never_in_meetings(8, -1, 13)[0][:measure]) < (x1[0][:measure]))
    end

    it 'adding manager with no meeting should raise group\'s score' do
      allow(AlgorithmsHelper).to receive(:is_less_than_100_emps).and_return(false)
      x1 = AlgorithmsHelper.proportion_of_managers_never_in_meetings(8, -1, 6)
      Employee.create!(id: 6, company_id: 2, group_id: 6, email: 'gqr@mail.com', external_id: '10413', first_name: 'Ger', last_name: 'Levi')
      EmployeeManagementRelation.create(manager_id: 6, employee_id: 5, relation_type: 2)
      expect((AlgorithmsHelper.proportion_of_managers_never_in_meetings(8, -1, 6)[0][:measure]) > (x1[0][:measure]))
    end

    it 'Should be 0 for small groups' do
      expect(AlgorithmsHelper.proportion_of_managers_never_in_meetings(8, -1, 8)[0][:measure]).to eq(0.0)
    end
  end

  describe 'Test powerful non reciprocity' do
    before(:each) do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 2)
      Company.create!(id: 2, name: 'testcom', randomize_image: true, active: true)
      snapshot_factory_create(id: 45, name: '2015-06', snapshot_type: 3, company_id: 2)
      Group.create!(id: 28, name: 'CS', company_id: 2, parent_group_id: nil)
      Employee.create!(id: 1, company_id: 2, email: 'pete@sala.com', external_id: '14', first_name: 'Dave', last_name: 'sala', group_id: 28)
      Employee.create!(id: 2, company_id: 2, email: 'frank@sala.com', external_id: '15', first_name: 'Dave1', last_name: 'sala', group_id: 28)
      Employee.create!(id: 3, company_id: 2, email: 'bill@sala.com', external_id: '16', first_name: 'Dave2', last_name: 'sala', group_id: 28)
      Employee.create!(id: 4, company_id: 2, email: 'da@sala.com', external_id: '17', first_name: 'Dave3', last_name: 'sala', group_id: 28)
      Employee.create!(id: 5, company_id: 2, email: 'dar@sala.com', external_id: '18', first_name: 'Dave4', last_name: 'sala', group_id: 28)

      NetworkName.create!(id: 2, name: 'Trust', company_id: 2)
      NetworkName.create!(id: 3, name: 'Friendship', company_id: 2)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 2, snapshot_id: 45, n1: 1, n2: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 2, employee_to_id: 1, snapshot_id: 45, n1: 1, n2: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 4, snapshot_id: 45, n1: 1, n2: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 3, snapshot_id: 45, n1: 1, n2: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 1, snapshot_id: 45, n1: 1, n2: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 5, snapshot_id: 45, n1: 1, n2: 1)

      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 1, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 2, to_employee_id: 1, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 4, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 3, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 5, to_employee_id: 1, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 1, to_employee_id: 5, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 1, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 2, to_employee_id: 1, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 4, to_employee_id: 3, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 3, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 5, to_employee_id: 1, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 1, to_employee_id: 5, value: 1)
    end

    it 'everyone should have same non-reciprocity' do
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(45, 2, 3, -1, 28)
      expect(res.length).to eq(0)
    end

    it 'emp 3 is non reciprocal in trust, but not friendship and emails, so he is not flagged' do
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 3, to_employee_id: 5, value: 1)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(45, 2, 3, -1, 28)
      expect(res).not_to include(id: 3, measure: 1)
      expect(res.count).to eq(0)
    end

    it 'emp 3 is non reciprocal in trust and friendships, but not emails, so he is not flagged' do
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 3, to_employee_id: 5, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 3, to_employee_id: 5, value: 1)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(45, 2, 3, -1, 28)
      expect(res.count).to eq(0)
    end

    it 'emp 3 is non reciprocal in trust and friendships and emails, so he is flagged' do
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 3, to_employee_id: 5, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 3, to_employee_id: 5, value: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 1, snapshot_id: 45, n1: 1, n2: 10)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(45, 2, 3, -1, 28)
      expect(res).to include(id: 3, measure: 1)
      expect(res.count).to eq(1)
    end

    it 'emp 5 is also flagged for non reciprocity along with 3' do
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 3, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 3, to_employee_id: 1, value: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 5, snapshot_id: 45, n1: 1, n18: 10)

      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 2, from_employee_id: 5, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 5, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 2, snapshot_id: 45, n1: 1, n9: 8)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(45, 2, 3, -1, 28)
      expect(res).to include(id: 5, measure: 1)
      expect(res).to include(id: 3, measure: 1)
      expect(res.count).to eq(2)
    end

    it 'non-reciprocity still works when there are no emails' do
      NetworkSnapshotData.create!(snapshot_id: 45, network_id: 3, company_id: 2, from_employee_id: 4, to_employee_id: 5, value: 1)
      NetworkSnapshotData.delete_all
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(45, 2, 3, -1, 28)
      expect(res.count).to eq(0)
    end

    it 'non-reciprocity does not work when one network is missing' do
      NetworkSnapshotData.where(network_id: 2).destroy_all
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 1, snapshot_id: 45, n1: 1, n2: 10)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(45, 2, 3, -1, 28)
      expect(res.count).to eq(0)
    end

    it 'non-reciprocity does not work when two networks are missing' do
      NetworkSnapshotData.delete_all
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 1, snapshot_id: 45, n1: 1, n2: 10)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(45, 2, 3, -1, 28)
      expect(res.count).to eq(0)
    end
  end
end
