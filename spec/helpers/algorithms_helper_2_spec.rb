
require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryGirl::Syntax::Methods

include CompanyWithMetricsFactory

IN = 'to_employee_id'
OUT  = 'from_employee_id'
TO_MATRIX ||= 1
CC_MATRIX ||= 2
BCC_MATRIX ||= 3

describe AlgorithmsHelper, type: :helper do

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'test bottleneck' do
    before do
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
    end

    describe 'calculate_bottlenecks_for_flag' do
      before do
        Employee.delete_all

        create_emps('stark', 'acme.com', 10, {gid: 6})
      end

      xit 'Everyone talk with 5 and 5 talks with everyone' do
        all = [
          [0,0,0,0,0,1,0,0,0,0],
          [0,0,0,0,0,1,0,0,0,0],
          [0,0,0,0,0,1,0,0,0,0],
          [0,0,0,0,0,1,0,0,0,0],
          [0,0,0,0,0,1,0,0,0,0],
          [1,1,1,1,1,1,1,1,1,1],
          [0,0,0,0,0,1,0,0,0,0],
          [0,0,0,0,0,1,0,0,0,0],
          [0,0,0,0,0,1,0,0,0,0],
          [0,0,0,0,0,1,0,0,0,0]]

        fg_emails_from_matrix(all)
        res = AlgorithmsHelper.calculate_bottlenecks_for_flag(1, -1, 6)
        expect(res).to include({id:5, measure:1})
      end

      xit 'There are two distinct groups talking only through 5' do
        all = [
          [0,0,0,1,0, 0, 0,0,0,0],
          [0,0,0,0,1, 0, 0,0,0,0],
          [1,1,0,1,0, 0, 0,0,0,0],
          [1,1,1,1,1, 9, 0,0,0,0],
          [0,0,0,0,1, 9, 0,0,0,0],

          [0,0,9,9,9, 1, 9,9,0,0],

          [0,0,0,0,0, 9, 0,1,0,0],
          [0,0,0,0,0, 9, 0,0,1,0],
          [0,0,0,0,0, 0, 1,1,0,1],
          [0,0,0,0,0, 0, 0,1,1,0]]

        fg_emails_from_matrix(all)
        res = AlgorithmsHelper.calculate_bottlenecks_for_flag(1, -1, 6)
        expect(res).to include({id:5, measure:1})
      end
    end
  end

  describe 'centrality of a boolean network' do
    before(:each) do
      @s = FactoryGirl.create(:snapshot, name: 's3', company_id: 1)
      em0 = 'p0@email.com'
      em1 = 'p1@email.com'
      em2 = 'p2@email.com'
      em3 = 'p3@email.com'
      @e1 = FactoryGirl.create(:employee, email: em0, group_id: 3)
      @e2 = FactoryGirl.create(:employee, email: em1, group_id: 3)
      @e3 = FactoryGirl.create(:employee, email: em2, group_id: 3)
      @e4 = FactoryGirl.create(:employee, email: em3, group_id: 3)
      @n1 = FactoryGirl.create(:network_name, name: 'Trust', company_id: 0)
    end

    it 'calculate high centrality value for boolean network' do
      NetworkSnapshotData.create(from_employee_id: @e2.id, to_employee_id: @e1.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e3.id, to_employee_id: @e1.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e4.id, to_employee_id: @e1.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      centrality = centrality_boolean_matrix(@s.id, -1, -1, @n1.id)
      expect(centrality).to eq(1.5)
    end

    it 'calculate low centrality value for boolean network' do
      NetworkSnapshotData.create(from_employee_id: @e1.id, to_employee_id: @e2.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e1.id, to_employee_id: @e3.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e1.id, to_employee_id: @e4.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e2.id, to_employee_id: @e1.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e2.id, to_employee_id: @e3.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e2.id, to_employee_id: @e4.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e3.id, to_employee_id: @e2.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e3.id, to_employee_id: @e1.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e3.id, to_employee_id: @e4.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e4.id, to_employee_id: @e1.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e4.id, to_employee_id: @e2.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e4.id, to_employee_id: @e3.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      ##centrality = centrality_boolean_matrix(@s.id, -1, -1, @n1.id)
      ##expect(centrality).to eq(0.0)
    end

    it 'company with two centralities boolean networks' do
      @e5 = FactoryGirl.create(:employee, email: 'p5@email.com', group_id: 3)
      @e6 = FactoryGirl.create(:employee, email: 'p6@email.com', group_id: 3)
      @e7 = FactoryGirl.create(:employee, email: 'p7@email.com', group_id: 3)
      @e8 = FactoryGirl.create(:employee, email: 'p8@email.com', group_id: 3)

      ## We have one central emp - 5
      NetworkSnapshotData.create(from_employee_id: @e1.id, to_employee_id: @e5.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e2.id, to_employee_id: @e5.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      centrality1 = centrality_boolean_matrix(@s.id, -1, -1, @n1.id)

      ## Now, 7 also becomes central
      NetworkSnapshotData.create(from_employee_id: @e3.id, to_employee_id: @e7.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e4.id, to_employee_id: @e7.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e5.id, to_employee_id: @e7.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      centrality2 = centrality_boolean_matrix(@s.id, -1, -1, @n1.id)

      expect(centrality2).to be > centrality1

      ## Now 5 and 7 communicate with each other
      NetworkSnapshotData.create(from_employee_id: @e5.id, to_employee_id: @e7.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e7.id, to_employee_id: @e5.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      centrality3 = centrality_boolean_matrix(@s.id, -1, -1, @n1.id)

      expect(centrality3).to be > centrality2

      ## Now there's a bunch of communication going on with other employees too
      NetworkSnapshotData.create(from_employee_id: @e5.id, to_employee_id: @e1.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e5.id, to_employee_id: @e2.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e7.id, to_employee_id: @e3.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      NetworkSnapshotData.create(from_employee_id: @e7.id, to_employee_id: @e4.id, value: 1, snapshot_id: 1, company_id: 0, network_id: @n1.id)
      centrality4 = centrality_boolean_matrix(@s.id, -1, -1, @n1.id)

      expect(centrality4).to be < centrality3
    end
  end

  describe 'centrality for integer network' do
    before(:each) do
      @s = FactoryGirl.create(:snapshot, name: 's3', company_id: 1)
      @e1 = FactoryGirl.create(:employee, email: 'em0@email.com', group_id: 3)
      @e2 = FactoryGirl.create(:employee, email: 'em1@email.com', group_id: 3)
      @e3 = FactoryGirl.create(:employee, email: 'em2@email.com', group_id: 3)
      @e4 = FactoryGirl.create(:employee, email: 'em3@email.com', group_id: 3)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
    end

    it 'calculate high centrality value for integner network' do
      emp2to1id = NetworkSnapshotData.create_email_adapter(employee_from_id: @e2.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e3.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e4.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e4.id, employee_to_id: @e2.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull)

      centrality1 = centrality_numeric_matrix(@s.id, -1, -1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e2.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 19, significant_level: :meaningfull)
      # emp2to1id.update(n1: 20)
      centrality2 = centrality_numeric_matrix(@s.id, -1, -1)
      expect(centrality2).to be > centrality1
    end

    it 'calculate low centrality value for integner network' do
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e3.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e4.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 3, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e4.id, employee_to_id: @e2.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e2.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 1)

      centrality1 = centrality_numeric_matrix(@s.id, -1, -1)

      NetworkSnapshotData.last.delete
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e2.id, employee_to_id: @e3.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull)
      centrality2 = centrality_numeric_matrix(@s.id, -1, -1)
      expect(centrality2).to be < centrality1
    end

    it 'centrality value for integner network should be zero for small groups' do
      gid = Group.create!(company_id: 1, name: 'Some Group')
      @e5 = FactoryGirl.create(:employee, email: 'em5@email.com', group_id: gid)
      @e6 = FactoryGirl.create(:employee, email: 'em6@email.com', group_id: gid)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e5.id, employee_to_id: @e6.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull)
      centrality = centrality_numeric_matrix(@s.id, gid, -1)
      expect(centrality).to be(0.0)
    end

    it 'should not faile if there is no email traffic' do
      centrality = centrality_numeric_matrix(@s.id, -1, -1)
      expect(centrality.nan?).to be_truthy
    end
  end

  describe 'density_of_email_network' do
    advice_network_id = 1
    before(:each) do
      fg_create(:company, id: 1)
      fg_create(:snapshot, id: 1, name: 's3', company_id: 1)
      fg_create(:group, id: 1)
      create_emps('name', 'acme.com', 4)
      NetworkSnapshotData.delete_all
    end

    it 'density is higher when everyone sends emails with uniform volumes' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      fg_multi_create_email_snapshot_data(4, 0)
      fg_multi_create_network_snapshot_data(4, 0)
      s_sum1 = AlgorithmsHelper.density_of_email_network(1, -1, -1, advice_network_id)
      ## Now some of the employees do not send emails
      NetworkSnapshotData.where("from_employee_id in (1,2)").delete_all
      s_sum2 = AlgorithmsHelper.density_of_email_network(1, -1, -1, advice_network_id)
      expect(s_sum1[0][:measure]).to be > s_sum2[0][:measure]
    end

    xit 'density is lower when everyone sends emails with uniform volumes except for one employee who sends a lot' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      fg_multi_create_email_snapshot_data(4, 0, 1)
      fg_multi_create_network_snapshot_data(4, 0)
      s_sum1 = AlgorithmsHelper.density_of_email_network(1, -1, -1, advice_network_id)
      ## Now someone sends a lot of emails
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 4,  snapshot_id: 1, n3: 300)
      # EmailSnapshotData.find(1).update(n3: 300)
      s_sum2 = AlgorithmsHelper.density_of_email_network(1, -1, -1, advice_network_id)
      expect(s_sum1[0][:measure]).to be > s_sum2[0][:measure]
    end

    it 'should be zero if there is no traffic' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      s_sum = AlgorithmsHelper.density_of_email_network(1, -1, -1, advice_network_id)
      expect(s_sum[0][:measure]).to eq(0.0)
    end

    xit 'should work with emails only' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      fg_multi_create_email_snapshot_data(4, 0)
      s_sum = AlgorithmsHelper.density_of_email_network(1, -1, -1, advice_network_id)
      expect(s_sum[0][:measure]).to be > 0.0
    end

    it 'should work with network only' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      fg_multi_create_network_snapshot_data(4, 0)
      s_sum = AlgorithmsHelper.density_of_email_network(1, -1, -1, advice_network_id)
      expect(s_sum[0][:measure]).to be > 0.0
    end

    it 'should return 0 for groups smaller than 4 emps' do
      fg_create(:group, id: 2)
      create_emps('name', 'acme.com', 3, {gid: 2, from_index: 6})
      s_sum = AlgorithmsHelper.density_of_email_network(1, 2, -1, advice_network_id)
      expect(s_sum[0][:measure]).to eq(0.0)
    end
  end

  describe 'calculate_gauge_parameters' do
    it 'should calculate gauge params' do
      allow(AlgorithmsHelper).to receive(:retrieve_gauge_values).and_return([1,2,3,4,5,6,7,8,9,10])
      gauge_params = AlgorithmsHelper::calculate_gauge_parameters(1,1,1,1)
      expect(gauge_params[:min_range]).to eq(1.0)
      expect(gauge_params[:max_range]).to eq(10.0)
      expect(gauge_params[:min_range_wanted]).to eq(3.0)
      expect(gauge_params[:max_range_wanted]).to eq(8.0)
    end

    it 'test a short sequence' do
      allow(AlgorithmsHelper).to receive(:retrieve_gauge_values).and_return([1,2,3,4])
      gauge_params = AlgorithmsHelper::calculate_gauge_parameters(1,126,1,1)
      expect(gauge_params[:min_range]).to eq(1)
      expect(gauge_params[:max_range]).to eq(4)
      expect(gauge_params[:min_range_wanted]).to eq(2)
      expect(gauge_params[:max_range_wanted]).to eq(3)
    end

    it 'test a flat sequence' do
      allow(AlgorithmsHelper).to receive(:retrieve_gauge_values).and_return([1,1,1,1,1,1,1,1])
      gauge_params = AlgorithmsHelper::calculate_gauge_parameters(1,126,1,1)
      expect(gauge_params[:min_range]).to eq(1)
      expect(gauge_params[:max_range]).to eq(1)
      expect(gauge_params[:min_range_wanted]).to eq(1)
      expect(gauge_params[:max_range_wanted]).to eq(1)
    end

    it 'test a half flat sequence' do
      allow(AlgorithmsHelper).to receive(:retrieve_gauge_values).and_return([1,1,1,1,1,4,5,6,7,8])
      gauge_params = AlgorithmsHelper::calculate_gauge_parameters(1,1,1,1)
      expect(gauge_params[:min_range]).to eq(1)
      expect(gauge_params[:max_range]).to eq(8)
      expect(gauge_params[:min_range_wanted]).to eq(1)
      expect(gauge_params[:max_range_wanted]).to eq(6)
    end
  end

  describe 'quartile functions' do
    it 'should get top value of lower quartile' do
      expect(AlgorithmsHelper::find_q1_max([1,2,3,4,5,6,7,8,9,10])).to be(3)
    end

    it 'should get top value of lower quartile' do
      expect(AlgorithmsHelper::find_q1_max([1,2,3,4])).to be(2)
    end

    it 'should get top value of lower quartile' do
      expect(AlgorithmsHelper::find_q1_max([1,2,3])).to be(2)
      expect(AlgorithmsHelper::find_q3_min([1,2,3])).to be(2)
    end

    it 'should get top value of lower quartile' do
      expect(AlgorithmsHelper::find_q3_min([1,2,3,4,5,6,7,8,9,10])).to eq(8)
    end

    it 'should get top value of lower quartile' do
      expect(AlgorithmsHelper::find_q1_max([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])).to eq(5)
    end

    it 'should get bottom value of upper quartile' do
      expect(AlgorithmsHelper::find_q3_min([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])).to eq(16)
    end
  end

  describe 'percentile functions' do
    before(:each) do
      @emps = [1,2,5,3,6,8,10,11]
      @scores = {'1'=>0.3, '2'=> 1.1, '8'=> 0.4, '6'=> 1.2, '3'=> 0.02, '10'=>0.9, '11'=>0.66, '12'=>1.3, '14'=>0.9}
    end

    it 'Find min quartile' do
      res = AlgorithmsHelper::slice_percentile_from_hash_array(@scores, AlgorithmsHelper::Q1)
      expect(res.count).to eq(3)
      expect(res[1][:id].to_i).to eq(1)
    end

    it 'Find max quartile' do
      res = AlgorithmsHelper::slice_percentile_from_hash_array(@scores, AlgorithmsHelper::Q3)
      expect(res.count).to eq(3)
      expect(res[1][:id].to_i).to eq(6)
    end

    it 'with empty list' do
      res = AlgorithmsHelper::slice_percentile_from_hash_array([], AlgorithmsHelper::Q3)
      expect(res.count).to eq(0)
    end

    it 'with nil list' do
      res = AlgorithmsHelper::slice_percentile_from_hash_array(nil, AlgorithmsHelper::Q3)
      expect(res.count).to eq(0)
    end

    it 'with small list' do
      scores = {'1'=>0.3, '2'=> 1.1, '8'=> 0.4, '6'=> 1.2}
      res = AlgorithmsHelper::slice_percentile_from_hash_array(scores, AlgorithmsHelper::Q3)
      expect(res.count).to eq(0)
    end

    it 'find min quartile with flat distribution from min to exactly q1' do
      scores = {'1'=>0.3, '2'=> 0.3, '3'=> 0.3, '4'=> 0.33, '5'=> 0.4, '6'=>0.9, '7'=>0.66, '8'=>1.3, '9'=>0.9, '10'=>1.5, '11'=>1.09, '12'=>1}
      res = AlgorithmsHelper::slice_percentile_from_hash_array(scores, AlgorithmsHelper::Q1)
      expect(res.count).to eq(3)
    end

    it 'find min quartile with flat distribution from min to q1 + 1' do
      scores = {'1'=>0.3, '2'=> 0.3, '3'=> 0.3, '4'=> 0.3, '5'=> 0.4, '6'=>0.9, '7'=>0.66, '8'=>1.3, '9'=>0.9, '10'=>1.5, '11'=>1.09, '12'=>1}
      res = AlgorithmsHelper::slice_percentile_from_hash_array(scores, AlgorithmsHelper::Q1)
      expect(res.count).to eq(0)
    end

    it 'find min quartile with flat distribution from min + 1 to q1 + 1' do
      scores = {'1'=>0.2, '2'=> 0.3, '3'=> 0.3, '4'=> 0.3, '5'=> 0.4, '6'=>0.9, '7'=>0.66, '8'=>1.3, '9'=>0.9, '10'=>1.5, '11'=>1.09, '12'=>1}
      res = AlgorithmsHelper::slice_percentile_from_hash_array(scores, AlgorithmsHelper::Q1)
      expect(res.count).to eq(1)
    end

    it 'should convert scores formatted as an array of hashs in to a hash' do
      scores = [{id: 1, measure: 0.1}, {id: 2, measure: 0.2}, {id: 3, measure: 0.3}, {id: 4, measure: 0.4}, {id: 5, measure: 0.5}]
      res = AlgorithmsHelper::slice_percentile_from_hash_array(scores, AlgorithmsHelper::Q1)
      expect(res.count).to eq(2)
    end
  end

  describe 'v_calc_max_traffic_between_two_employees_with_ids' do
    before(:each) do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      fg_create(:company, id: 1)
      fg_create(:snapshot, id: 1, name: 's3', company_id: 1)
      fg_create(:group, id: 1)
      create_emps('name', 'acme.com', 4)
    end

    it 'should return list of max values found' do
      fg_multi_create_email_snapshot_data(4, 3)
      # NetworkSnapshotData.find(4).delete
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 4,  snapshot_id: 1, n1: 10)
      expect(AlgorithmsHelper.s_calc_max_traffic_between_two_employees(1, -1, -1)).to eq(10)    # changed to 10 due to original containing n2 results for an unknown reason
    end
    it 'should behave if no values' do
      Employee.delete_all
      expect(AlgorithmsHelper.s_calc_max_traffic_between_two_employees(1, -1, -1)).to be_nil
    end
  end

  describe 's_calc_sum_of_metrix' do
    before(:each) do
      fg_create(:company, id: 1)
      fg_create(:snapshot, id: 1, name: 's3', company_id: 1)
      fg_create(:group, id: 1)
      create_emps('name', 'acme.com', 4)
    end

    it 'should count all traffic in emails' do
      fg_multi_create_email_snapshot_data(4, 3, 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 1, employee_to_id: 4,  snapshot_id: 1, n1: 10)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 2,  snapshot_id: 1, n1: 7)
      s_sum = AlgorithmsHelper.s_calc_sum_of_metrix(1, -1, -1, 123)
      expect(s_sum).to eq(25)
    end

    it 'should count all traffic in network 1' do
      fg_multi_create_network_snapshot_data(4)
      s_sum = AlgorithmsHelper.s_calc_sum_of_metrix(1, -1, -1, 1)
      expect(s_sum).to eq(8)
    end

    it 'should not fail when there is no email traffic' do
      s_sum = AlgorithmsHelper.s_calc_sum_of_metrix(1, -1, -1)
      expect(s_sum).to eq(0)
    end

    it 'should not fail when there is no network traffic' do
      s_sum = AlgorithmsHelper.s_calc_sum_of_metrix(1, -1, -1, 13)
      expect(s_sum).to eq(0)
    end
  end
end
