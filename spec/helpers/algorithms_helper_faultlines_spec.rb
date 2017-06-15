require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryGirl::Syntax::Methods

describe AlgorithmsHelper, type: :helper do

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'external faultlines' do
    it 'empty network' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Group.create!(id: 3, name: "R&D2", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)

      Employee.create!(id: 1, company_id: 1, email: "garw@mail.com", external_id: "10045", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 3, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 2, company_id: 1, email: "halw@mail.com", external_id: "100146", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 4, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 3, company_id: 1, email: "kenw@mail.com", external_id: "10047", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 5, company_id: 1, email: "fraw@mail.com", external_id: "10048", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 6, company_id: 1, email: "bobw@mail.com", external_id: "10049", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 7, company_id: 1, email: "gerw@mail.com", external_id: "10060", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
      NetworkName.create!(id: 2, name: 'Friendship', company_id: 1)
      NetworkName.create!(id: 3, name: 'Trust', company_id: 1)
      [[13,15],[13,21],[15,13],[15,21], [15,11],[15,14],[21,11],[11,15],[11,21],[11,4],[14,13],[14,11],[14,15],[14,4],[4,13],[4,15],[4,14]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[13,15],[13,21],[4,15],[21,11],[11,15],[11,21],[4,14],[15,21],[15,11],[13,14],[4,13],[14,13],[14,11],[14,21],[11,4],[14,4]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 13, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 13, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 2, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 1, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 1, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 2)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 3, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 7, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 1, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 1, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 4, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 0, n2: 3, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 2, n4: 0, n5: 2, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      expect(AlgorithmsHelper.calculate_external_faultlines(1, 1,2,3, -1, 6)[0][:measure]).to be == -1
    end
    it 'smaller external group' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Group.create!(id: 3, name: "R&D2", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)

      Employee.create!(id: 1, company_id: 1, email: "garw@mail.com", external_id: "10045", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 3, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 2, company_id: 1, email: "halw@mail.com", external_id: "100146", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 4, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 3, company_id: 1, email: "kenw@mail.com", external_id: "10047", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 5, company_id: 1, email: "fraw@mail.com", external_id: "10048", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 6, company_id: 1, email: "bobw@mail.com", external_id: "10049", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 7, company_id: 1, email: "gerw@mail.com", external_id: "10060", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
      NetworkName.create!(id: 2, name: 'Friendship', company_id: 1)
      NetworkName.create!(id: 3, name: 'Trust', company_id: 1)
      [[13,15],[13,21],[15,13],[15,21], [15,11],[15,14],[21,11],[11,15],[11,21],[11,4],[14,13],[14,11],[14,15],[14,4],[4,13],[4,15],[4,14]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[13,15],[13,21],[4,15],[21,11],[11,15],[11,21],[4,14],[15,21],[15,11],[13,14],[4,13],[14,13],[14,11],[14,21],[11,4],[14,4]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[1,2],[3,5],[5,6],[7,1], [6,7],[1,7],[2,3],[1,5],[2,6],[1,3],[5,3],[2,5],[3,6],[5,7],[3,1],[2,1]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[13,21],[13,4],[15,13],[15,21], [15,11],[21,15],[21,11],[21,4],[21,14],[11,14],[11,14],[4,13],[4,15],[4,11],[4,14],[4,13],[14,11]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 2, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 1, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 1, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 2)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 3, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 7, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 1, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 1, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 4, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 0, n2: 3, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 2, n4: 0, n5: 2, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      expect(AlgorithmsHelper.calculate_external_faultlines(1, 1,2,3, -1, 6)[0][:measure]).to be == -0.7575757575757576
    end

    it 'smaller external group' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Group.create!(id: 3, name: "R&D2", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)

      Employee.create!(id: 1, company_id: 1, email: "garw@mail.com", external_id: "10045", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 3, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 2, company_id: 1, email: "halw@mail.com", external_id: "100146", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 4, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 3, company_id: 1, email: "kenw@mail.com", external_id: "10047", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 5, company_id: 1, email: "fraw@mail.com", external_id: "10048", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 6, company_id: 1, email: "bobw@mail.com", external_id: "10049", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 7, company_id: 1, email: "gerw@mail.com", external_id: "10060", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 3, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
      NetworkName.create!(id: 2, name: 'Friendship', company_id: 1)
      NetworkName.create!(id: 3, name: 'Trust', company_id: 1)
      [[13,15],[13,21],[15,13],[15,21], [15,11],[15,14],[21,11],[11,15],[11,21],[11,4],[14,13],[14,11],[14,15],[14,4],[4,13],[4,15],[4,14]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[13,15],[13,21],[4,15],[21,11],[11,15],[11,21],[4,14],[15,21],[15,11],[13,14],[4,13],[14,13],[14,11],[14,21],[11,4],[14,4]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[1,2],[3,5],[5,6],[7,1], [6,7],[1,7],[2,3],[1,5],[2,6],[1,3],[5,3],[2,5],[3,6],[5,7],[3,1],[2,1]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[13,21],[13,4],[15,13],[15,21], [15,11],[21,15],[21,11],[21,4],[21,14],[11,14],[11,14],[4,13],[4,15],[4,11],[4,14],[4,13],[14,11]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      [[1,2],[3,5],[5,6],[7,1], [6,7],[1,7],[2,3],[1,5],[2,6],[1,3],[5,3],[2,5],[3,6],[5,7],[3,1],[2,1],[13,1]].each do |couple|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: couple[0], to_employee_id: couple[1], value: 1)
      end
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 2, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 1, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 1, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 2)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 3, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 7, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 1, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 1, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 4, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 0, n2: 3, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 2, n4: 0, n5: 2, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      expect(AlgorithmsHelper.calculate_external_faultlines(1, 1,2,3, -1, 6)[0][:measure]).to be == -0.5075757575757576
    end
  end

  describe 'Test internal faultline' do
    it 'expect calculate_internal_faultlines_for_network to yield correct results' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
      NetworkName.create!(id: 2, name: 'Friendship', company_id: 1)
      NetworkName.create!(id: 3, name: 'Trust', company_id: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 13, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 13, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 13, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 13, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 13, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 15, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 21, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 21, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 11, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 11, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 11, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 14, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 13, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 13, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 13, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 21, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 4, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 4, to_employee_id: 11, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 2, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 1, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 1, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 2)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 3, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 7, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 1, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 1, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 4, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 0, n2: 3, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 2, n4: 0, n5: 2, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      expect(AlgorithmsHelper.calculate_internal_faultlines(1, 1, 2, 3, -1, 6, "gender")[0][:measure]).to be == 3359.to_f / 21488.to_f
    end
   it 'expect calculate_internal_faultlines_for_network without emails' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
      NetworkName.create!(id: 2, name: 'Friendship', company_id: 1)
      NetworkName.create!(id: 3, name: 'Trust', company_id: 1)
      obj_array = [[13,21],[13,4],[15,13],[15,21],[15,11],[15,14],[21,15],[21, 11],[21,4],[21,14],[11,14],[4,13],[4,15],[4,11],[4,14],[14,13],[14,11]]#,[13,15],[13,4],[13,14],[15,4],[15,11],[21,15],[21,13],[21,14],[11,13],[11,15],[11,4],[11,14],[4,21],[14,4],[14,13],[14,11],[13,15],[13,11],[15,13],[15,11],[15,4],[21,13],[21,14],[21,4],[11,13],[11,21],[11,14],[4,21],[4,11],[14,13],[14,15],[14,11]]
      obj_array.each do |obj|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: obj[0], to_employee_id: obj[1], value: 1)
      end
      obj_array = [[13,15],[13,4],[13,14],[15,4],[15,11],[21,15],[21,13],[21,14],[11,13],[11,15],[11,4],[11,14],[4,21],[14,4],[14,13],[14,11]]#,[13,15],[13,11],[15,13],[15,11],[15,4],[21,13],[21,14],[21,4],[11,13],[11,21],[11,14],[4,21],[4,11],[14,13],[14,15],[14,11]]
      obj_array.each do |obj|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: obj[0], to_employee_id: obj[1], value: 1)
      end
      obj_array = [[13,15],[13,11],[15,13],[15,11],[15,4],[21,13],[21,14],[21,4],[11,13],[11,21],[11,14],[4,21],[4,11],[14,13],[14,15],[14,11]]
      obj_array.each do |obj|
        NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: obj[0], to_employee_id: obj[1], value: 1)
      end
      expect(AlgorithmsHelper.calculate_internal_faultlines(1, 1, 2, 3, -1, 6, "gender")[0][:measure]).to be == 21.to_f / 272.to_f
    end
    it 'expect calculate_internal_faultlines_for_network to yield correct results with missing network' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 3, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 1, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 1, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", date_of_birth: nil, employment: nil, gender: 0, group_id: 6, home_address: nil, job_title_id: nil, marital_status_id: nil, middle_name: nil, position_scope: nil, qualifications: nil, rank_id: 2, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
      NetworkName.create!(id: 2, name: 'Friendship', company_id: 1)
      NetworkName.create!(id: 3, name: 'Trust', company_id: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 13, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 13, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 13, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 13, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 13, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 21, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 4, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 4, to_employee_id: 11, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 2, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 13, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 2, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 1, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 1, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 15, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 21, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 2)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 3, n8: 1, n9: 0, n10: 0, n11: 0, n12: 0, n13: 1,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 7, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 11, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 1, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 1, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 4, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 4, employee_to_id: 14, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 13, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 1, n5: 0, n6: 1, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 15, snapshot_id: 1, weight: 0, n1: 0, n2: 1, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 21, snapshot_id: 1, weight: 0, n1: 0, n2: 3, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 2, n13: 0,n14: 1, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 11, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 0, n4: 0, n5: 0, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 14, employee_to_id: 4, snapshot_id: 1, weight: 0, n1: 1, n2: 0, n3: 2, n4: 0, n5: 2, n6: 0, n7: 0, n8: 0, n9: 0, n10: 0, n11: 0, n12: 0, n13: 0,n14: 0, n15: 0, n16: 0, n17: 0, n18: 0)

      expect(AlgorithmsHelper.calculate_internal_faultlines(1, 1, 2, 3, -1, 6, "gender")[0][:measure]).to be == (0.125+(1.to_f/17.to_f)+25.to_f / 79.to_f)/4
    end

    it 'expect calculate_internal_faultlines_for_network to return null because of too few employees in the rubric' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      Company.find_or_create_by(id: 1, name: "Hevra10")
      snapshot_factory_create({id: 1, name: "2016-01", snapshot_type: nil, company_id: 1})
      Group.create!(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, created_at: nil, updated_at: nil)
      Employee.create!(id: 13, company_id: 1, email: "gar@mail.com", external_id: "10012", first_name: "Gar", last_name: "Levi", gender: 1, group_id: 6, role_id: 6, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/gar%40mail.com....", img_url_last_updated: "2016-03-27 08:01:20", color_id: 8, created_at: "2015-01-04 11:40:33", updated_at: "2016-04-19 08:51:11", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 15, company_id: 1, email: "hal@mail.com", external_id: "10014", first_name: "Hal", last_name: "Levi", gender: 0, group_id: 6, role_id: 6, office_id: 4, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/hal%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:48", updated_at: "2016-04-19 09:05:37", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 21, company_id: 1, email: "ken@mail.com", external_id: "10020", first_name: "Ken", last_name: "Levi", gender: 1, group_id: 6, role_id: 2, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ken%40mail.com....", img_url_last_updated: "2016-03-27 08:01:24", color_id: 6, created_at: "2015-01-04 11:42:03", updated_at: "2016-04-19 09:13:27", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 11, company_id: 1, email: "fra@mail.com", external_id: "10010", first_name: "Fra", last_name: "Levi", gender: 0, group_id: 6, role_id: 2, office_id: 3, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/fra%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 9, created_at: "2015-01-04 11:40:13", updated_at: "2016-04-19 09:14:02", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 4, company_id: 1, email: "bob@mail.com", external_id: "10003", first_name: "Bob", last_name: "Levi",  gender: 1, group_id: 6, role_id: 4, office_id: 6, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/bob%40mail.com....", img_url_last_updated: "2016-03-27 08:01:25", color_id: 4, created_at: "2015-01-04 11:39:00", updated_at: "2016-03-27 08:01:25", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      Employee.create!(id: 14, company_id: 1, email: "ger@mail.com", external_id: "10013", first_name: "Ger", last_name: "Levi", gender: 0, group_id: 6, role_id: 4, office_id: 5, work_start_date: nil, img_url: "https://workships.s3.amazonaws.com/ger%40mail.com....", img_url_last_updated: "2016-03-27 08:01:26", color_id: 7, created_at: "2015-01-04 11:40:41", updated_at: "2016-04-18 13:53:58", age_group_id: nil, seniority_id: nil, formal_level: 2, active: true, phone_number: nil)
      NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
      NetworkName.create!(id: 2, name: 'Friendship', company_id: 1)
      NetworkName.create!(id: 3, name: 'Trust', company_id: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 13, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 13, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 15, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 4, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 13, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 13, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 13, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 15, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 21, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 21, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 11, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 11, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 11, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 14, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 2, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 13, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 13, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 15, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 21, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 11, to_employee_id: 14, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 4, to_employee_id: 21, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 4, to_employee_id: 11, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 13, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 15, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: 3, company_id: 1, from_employee_id: 14, to_employee_id: 11, value: 1)

      res = AlgorithmsHelper.calculate_internal_faultlines(1, 1, 2, 3, -1, 6, "role_id")
      expect(res[0][:measure].round(3)).to be == 0.506
    end
  end
end
