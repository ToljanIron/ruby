
require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryBot::Syntax::Methods

include CompanyWithMetricsFactory

IN = 'to_employee_id'
OUT  = 'from_employee_id'
TO_MATRIX ||= 1
CC_MATRIX ||= 2
BCC_MATRIX ||= 3

describe AlgorithmsHelper, type: :helper do

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
  end

  describe 'centrality for integer network |' do
    before(:each) do
      @cid = FactoryBot.create(:company).id
      @s = FactoryBot.create(:snapshot, name: 's3', company_id: @cid)
      @e1 = FactoryBot.create(:employee, email: 'em0@email.com', group_id: 3)
      @e2 = FactoryBot.create(:employee, email: 'em1@email.com', group_id: 3)
      @e3 = FactoryBot.create(:employee, email: 'em2@email.com', group_id: 3)
      @e4 = FactoryBot.create(:employee, email: 'em3@email.com', group_id: 3)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
    end

    it 'calculate high centrality value for integer network' do
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e2.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull, company_id: @cid)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e3.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull, company_id: @cid)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e4.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 3, significant_level: :meaningfull, company_id: @cid)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e4.id, employee_to_id: @e2.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull, company_id: @cid)

      centrality1 = centrality_numeric_matrix(@s.id, -1, -1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e2.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 19, significant_level: :meaningfull, company_id: @cid)
      centrality2 = centrality_numeric_matrix(@s.id, -1, -1)
      expect(centrality2).to be > centrality1
    end

    it 'calculate low centrality value for integner network' do
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e3.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull, company_id: @cid)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e4.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 3, significant_level: :meaningfull, company_id: @cid)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e4.id, employee_to_id: @e2.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull, company_id: @cid)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e2.id, employee_to_id: @e1.id, snapshot_id: @s.id, n1: 1, company_id: @cid)

      centrality1 = centrality_numeric_matrix(@s.id, -1, -1)

      NetworkSnapshotData.last.delete
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e2.id, employee_to_id: @e3.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull, company_id: @cid)
      centrality2 = centrality_numeric_matrix(@s.id, -1, -1)
      expect(centrality2).to be < centrality1
    end

    it 'centrality value for integner network should be zero for small groups' do
      gid = Group.create!(company_id: 1, name: 'Some Group').id
      @e5 = FactoryBot.create(:employee, email: 'em5@email.com', group_id: gid)
      @e6 = FactoryBot.create(:employee, email: 'em6@email.com', group_id: gid)
      NetworkSnapshotData.create_email_adapter(employee_from_id: @e5.id, employee_to_id: @e6.id, snapshot_id: @s.id, n1: 1, significant_level: :meaningfull, company_id: @cid)
      centrality = centrality_numeric_matrix(@s.id, gid, -1)
      expect(centrality).to be(0.0)
    end

    it 'should not fail if there is no email traffic' do
      centrality = centrality_numeric_matrix(@s.id, -1, -1)
      expect(centrality.nan?).to be_truthy
    end
  end

  describe 'density_of_network |' do
    before(:each) do
      @cid = fg_create(:company).id
      @sid = fg_create(:snapshot, id: 1, name: 's3', company_id: @cid).id
      @gid = fg_create(:group, id: 1).id
      create_emps('name', 'acme.com', 4, gid: @gid)
      @nid = NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1).id
    end

    it 'density is higher when everyone sends emails with uniform volumes' do
      fg_multi_create_network_snapshot_data(4, @sid, @cid, @nid, 4)
      s_sum1 = AlgorithmsHelper.density_of_network(1, @gid, -1, @nid)
      ## Now some of the employees do not send emails
      NetworkSnapshotData.where("from_employee_id in (1,2)").delete_all
      s_sum2 = AlgorithmsHelper.density_of_network(1, @gid, -1, @nid)
      expect(s_sum1[0][:measure]).to be > s_sum2[0][:measure]
    end

    it 'density is lower when everyone sends emails with uniform volumes except for one employee who sends a lot' do
      fg_multi_create_network_snapshot_data(4, @sid, @cid, @nid, 0)
      s_sum1 = AlgorithmsHelper.density_of_network(1, @gid, -1, @nid)
      ## Now someone sends a lot of emails
      FactoryBot.create(:network_snapshot_data, from_employee_id: 1, to_employee_id: 2, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid)
      FactoryBot.create(:network_snapshot_data, from_employee_id: 1, to_employee_id: 3, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid)
      FactoryBot.create(:network_snapshot_data, from_employee_id: 1, to_employee_id: 4, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid)
      FactoryBot.create(:network_snapshot_data, from_employee_id: 1, to_employee_id: 2, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid)

      s_sum2 = AlgorithmsHelper.density_of_network(1, @gid, -1, @nid)
      expect(s_sum1[0][:measure]).to be < s_sum2[0][:measure]
    end

    it 'should be zero if there is no traffic' do
      s_sum = AlgorithmsHelper.density_of_network(1, @gid, -1, @nid)
      expect(s_sum[0][:measure]).to eq(0.0)
    end

    it 'should work with emails only' do
      fg_multi_create_network_snapshot_data(4, @sid, @cid, @nid, 0)
      s_sum = AlgorithmsHelper.density_of_network(1, @gid, -1, @nid)
      expect(s_sum[0][:measure]).to be > 0.0
    end

    it 'should return 0 for groups smaller than 4 emps' do
      gid2 = fg_create(:group, id: 2).id
      create_emps('name', 'acme.com', 3, {gid: gid2, from_index: 6})
      s_sum = AlgorithmsHelper.density_of_network(1, gid2, -1, @nid)
      expect(s_sum[0][:measure]).to eq(0.0)
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
      @cid = fg_create(:company).id
      @sid = fg_create(:snapshot, name: 's3', company_id: 1).id
      @gid = fg_create(:group).id
      create_emps('name', 'acme.com', 4)
      @nid = NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: @cid).id
    end

    it 'should return list of max values found' do
      fg_multi_create_network_snapshot_data(4, @sid, @cid, @nid, 3)
      FactoryBot.create(:network_snapshot_data, from_employee_id: 1, to_employee_id: 4, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid)
      FactoryBot.create(:network_snapshot_data, from_employee_id: 4, to_employee_id: 1, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid)
      FactoryBot.create(:network_snapshot_data, from_employee_id: 1, to_employee_id: 3, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid)
      expect(AlgorithmsHelper.s_calc_max_traffic_between_two_employees(1, @nid, -1, -1)).to eq(3)
    end
    it 'should behave if no values' do
      Employee.delete_all
      expect(AlgorithmsHelper.s_calc_max_traffic_between_two_employees(1, -1, -1)).to be_nil
    end
  end

  describe 's_calc_sum_of_matrix' do
    before(:each) do
      fg_create(:company, id: 1)
      fg_create(:snapshot, id: 1, name: 's3', company_id: 1)
      fg_create(:group, id: 1)
      create_emps('name', 'acme.com', 4)
    end

    it 'should count all traffic in network 1' do
      fg_multi_create_network_snapshot_data(4,1,1,1,3)
      s_sum = AlgorithmsHelper.s_calc_sum_of_matrix(1, -1, -1, 1)
      expect(s_sum).to eq(8)
    end

    it 'should not fail when there is no email traffic' do
      s_sum = AlgorithmsHelper.s_calc_sum_of_matrix(1, -1, -1)
      expect(s_sum).to eq(0)
    end

    it 'should not fail when there is no network traffic' do
      s_sum = AlgorithmsHelper.s_calc_sum_of_matrix(1, -1, -1, 13)
      expect(s_sum).to eq(0)
    end
  end

  describe 'network_traffic_standard_err()' do
    before(:each) do
      @cid = fg_create(:company).id
      @sid = fg_create(:snapshot, name: 's3', company_id: @cid).id
      @gid = fg_create(:group).id

      em1 = 'p0@email.com'
      em2 = 'p1@email.com'
      em3 = 'p2@email.com'
      em4 = 'p3@email.com'
      @e1_id = FactoryBot.create(:employee, email: em1, group_id: @gid).id
      @e2_id = FactoryBot.create(:employee, email: em2, group_id: @gid).id
      @e3_id = FactoryBot.create(:employee, email: em3, group_id: @gid).id
      @e4_id = FactoryBot.create(:employee, email: em4, group_id: @gid).id

      @nid = NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1).id
    end

    it 'should calculate correct standard deviation' do
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e2_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e3_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e4_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      FactoryBot.create(:network_snapshot_data, from_employee_id: @e2_id, to_employee_id: @e1_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e2_id, to_employee_id: @e3_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      FactoryBot.create(:network_snapshot_data, from_employee_id: @e3_id, to_employee_id: @e1_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      FactoryBot.create(:network_snapshot_data, from_employee_id: @e4_id, to_employee_id: @e2_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      res = AlgorithmsHelper.network_traffic_standard_err(@sid, @gid, -1, @nid)
      expect(res[0][:measure] - 1.291).to be < (0.001)
    end

    it 'should give bigger standard deviation when employee that was sending/receiving more than average, started to send even more' do
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e2_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e3_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e4_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      FactoryBot.create(:network_snapshot_data, from_employee_id: @e2_id, to_employee_id: @e1_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e2_id, to_employee_id: @e3_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      FactoryBot.create(:network_snapshot_data, from_employee_id: @e3_id, to_employee_id: @e1_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      FactoryBot.create(:network_snapshot_data, from_employee_id: @e4_id, to_employee_id: @e2_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      res1 = AlgorithmsHelper.network_traffic_standard_err(@sid, @gid, -1, @nid)

      # employee 1 sends/receives a lot more emails now
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e2_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e3_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e4_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      res2 = AlgorithmsHelper.network_traffic_standard_err(@sid, @gid, -1, @nid)
      expect(res1[0][:measure]).to be < (res2[0][:measure])
    end

    it 'should return zero standard deviation for single employee in group' do
      FactoryBot.create(:network_snapshot_data, from_employee_id: @e1_id, to_employee_id: @e2_id, value: 1, snapshot_id: @sid, company_id: @cid, network_id: @nid, to_type: 1, from_type: 1)

      gid2 = fg_create(:group, id: 2).id
      @e5_id = FactoryBot.create(:employee, email: 'p5@email.com', group_id: gid2).id
      res = AlgorithmsHelper.network_traffic_standard_err(@sid, gid2, -1, @nid)
      expect(res[0][:measure]).to eq(0)
    end
  end
end
