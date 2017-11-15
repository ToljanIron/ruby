require 'nmatrix'
require 'pp'
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

  describe 'most isolated' do
    all = nil
    before do
      all = [
        [0,0,0,0,0,0,0,0,0,0],
        [1,0,4,0,0,0,0,0,0,0],
        [0,3,0,6,0,0,0,0,0,0],
        [0,4,5,0,5,0,0,0,0,0],
        [0,2,0,6,0,4,0,0,0,0],
        [0,0,0,0,3,0,0,0,0,0],
        [0,0,0,0,0,4,0,0,6,0],
        [0,0,0,0,0,0,5,2,0,0],
        [0,0,0,0,0,0,8,0,0,0],
        [0,1,1,1,1,1,1,1,1,1]]

      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      create_emps('moshe', 'acme.com', 10, {gid: 6})
    end

    it 'should rank employees by isolatation' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.most_isolated_workers(1, 6)
      expect(res[0][:id]).to eq(1)
      expect(res[0][:measure]).to eq(1)
    end

    it 'increasing number of emails increases the score' do
      fg_emails_from_matrix(all)
      res1 = AlgorithmsHelper.most_isolated_workers(1, 6)

      all[1][5] = 4
      NetworkSnapshotData.delete_all
      fg_emails_from_matrix(all)
      res2 = AlgorithmsHelper.most_isolated_workers(1, 6)

      score1 = res1.select { |e| e[:id] == 2}[0][:measure]
      score2 = res2.select { |e| e[:id] == 2}[0][:measure]
      expect(score2 - score1).to be > 0
    end

    it 'employee without connections should have score 0' do
      all[1][0] = 0
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.most_isolated_workers(1, 6)
      score = res.select { |e| e[:id] == 1}[0][:measure]
      expect(score).to eq(0)
    end

    it 'should return empty result for groups with less then 10 employees' do
      Employee.delete_all
      create_emps('moshe', 'acme.com', 9, {gid: 6})
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.most_isolated_workers(1, 6)
      expect(res).to eq([])
    end
  end

  describe 'powerful non-manager' do
    all = nil
    before do
      all = [
        [0,0,0,0,0,0,0,0,0,0],
        [1,0,4,0,0,0,0,0,0,0],
        [0,3,0,6,0,0,0,0,0,0],
        [0,4,5,0,5,0,0,0,0,0],
        [0,2,0,6,0,4,0,0,0,0],
        [0,0,0,0,3,0,0,0,0,0],
        [0,0,0,0,0,4,0,0,6,0],
        [0,0,0,0,0,0,5,2,0,0],
        [0,0,0,0,0,0,8,0,0,0],
        [0,1,1,1,1,1,1,1,1,1]]

      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      create_emps('moshe', 'acme.com', 10, {gid: 6})
    end

    it 'should rank employees by indegrees' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_powerful_non_managers(1, -1, 6)
      expect(res.first[:id]).to eq(7)
      expect(res.last[:id]).to eq(10)
      expect(res[0][:measure]).to be >= res[1][:measure]
    end

    it 'should not include a manager in the result' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_powerful_non_managers(1, -1, 6)
      expect(res.first[:id]).to eq(7)
      EmployeeManagementRelation.create!(manager_id: 7, employee_id: 4, relation_type: :recursive)
      res = AlgorithmsHelper.calculate_powerful_non_managers(1, -1, 6)
      expect(res.first[:id]).not_to eq(7)
    end
  end

  describe 'sagraph' do
    all = nil
    nid = nil
    cid = nil
    before do
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      nid = NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1).id
      cid = Snapshot.find(1).company_id
    end

    it 'should create a well formatted sagraph structre' do
      all = [
        [0,1,1,0,0,0,0,0,0,0],
        [1,0,1,0,0,0,0,0,0,0],
        [1,1,0,1,0,0,0,0,0,0],
        [0,0,1,0,1,0,0,0,0,0],
        [0,0,0,1,0,1,1,1,1,1],
        [0,0,0,1,1,0,1,1,1,1],
        [0,0,0,0,1,1,0,1,1,1],
        [0,0,0,0,1,1,1,0,1,1],
        [0,0,0,0,1,1,1,1,0,1],
        [0,0,0,0,1,1,1,1,1,0]]
      create_emps('moshe', 'acme.com', 10, {gid: 6})
      fg_emails_from_matrix(all)

      sagraph = get_sagraph(1, nid, 6)
      inx2emp = sagraph[:inx2emp]
      emp2inx = sagraph[:emp2inx]

      expect( emp2inx[inx2emp[0]] ).to eq(0)
      expect( inx2emp[emp2inx[7]] ).to eq(7)
      expect( sagraph[:adjacencymat].shape ).to eq([10,10])
      expect( sagraph[:adjacencymat].slice(7,6) ).to eq(1)
      expect( sagraph[:adjacencymat].slice(7,7) ).to eq(0)
    end

    it 'employees with no outgoing connections should have 1 on the diagonal entry' do
      all = [
        [0,1,1,0,0,0],
        [1,0,1,0,0,0],
        [1,1,0,1,0,0],
        [0,0,1,0,1,0],
        [0,0,0,0,0,0],
        [0,0,0,1,1,0]]
      create_emps('moshe', 'acme.com', 6, {gid: 6})
      fg_emails_from_matrix(all)
      sagraph = get_sagraph(1, nid, 6)

      a = sagraph[:adjacencymat]

      expect( a.slice(4,3) ).to eq(0)
      expect( a.slice(4,4) ).to eq(1)
      expect( a.slice(4,5) ).to eq(0)
    end

    describe 'get_sa_membership_matrix' do
      gids = nil
      emp2inx = nil
      group2inx = nil
      before do
        Company.find_or_create_by(id: 1, name: "Hevra10")
        Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
        FactoryGirl.create(:group, id: 11, name: 'g1')
        FactoryGirl.create(:group, id: 12, name: 'g2')
        FactoryGirl.create(:group, id: 13, name: 'g3')
        FactoryGirl.create(:group, id: 14, name: 'g4')
        FactoryGirl.create(:employee, id: 1, group_id: 11)
        FactoryGirl.create(:employee, id: 2, group_id: 11)
        FactoryGirl.create(:employee, id: 3, group_id: 12)
        FactoryGirl.create(:employee, id: 4, group_id: 12)
        FactoryGirl.create(:employee, id: 5, group_id: 12)
        FactoryGirl.create(:employee, id: 6, group_id: 14)
        FactoryGirl.create(:employee, id: 7, group_id: 14)
        FactoryGirl.create(:employee, id: 8, group_id: 14)
        gids = Group.pluck(:id)
        emp2inx = {}
        group2inx = {}
        (0..7).each do |i|
          emp2inx[i+1] = i
          group2inx[i + 11] = i if i < 4
        end
      end

      it 'should be well formed' do
        m = get_sa_membership_matrix(emp2inx, group2inx, gids)
        expect(m.shape).to eq([8,4])
        expect(m.column(2).to_a.flatten).to eq([0,0,0,0,0,0,0,0])
        expect(m.row(2).to_a).to eq([0,1,0,0])
      end
    end
  end

  describe 'bottlnecks' do
    all = nil
    nid = nil
    cid = nil
    before do
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      nid = NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1).id
      cid = Snapshot.find(1).company_id
    end

    it 'should create a well formatted sagraph structre' do
      all = [
        [0,1,1,0,0,0,0,0,0,0],
        [1,0,1,0,0,0,0,0,0,0],
        [1,1,0,1,0,0,0,0,0,0],
        [0,0,1,0,1,0,0,0,0,0],
        [0,0,0,1,0,1,1,1,1,1],
        [0,0,0,1,1,0,1,1,1,1],
        [0,0,0,0,1,1,0,1,1,1],
        [0,0,0,0,1,1,1,0,1,1],
        [0,0,0,0,1,1,1,1,0,1],
        [0,0,0,0,1,1,1,1,1,0]]
      create_emps('moshe', 'acme.com', 10, {gid: 6})
      fg_emails_from_matrix(all)

      bns = AlgorithmsHelper.calculate_bottlenecks(1, nid, 6)
      expect(bns[4][:measure]).to eq(0.137)
    end
  end

  describe 'reverse_scores' do
    arr = [
      {a: 'a1', s: 2},
      {a: 'a2', s: -1},
      {a: 'a3', s: 5},
      {a: 'a4', s: 1},
      {a: 'a5', s: 4}
    ]
    it 'should revers the scores' do
      res = AlgorithmsHelper.reverse_scores(arr, :s)
      expect(res[2][:s]).to eq(0)
      expect(res[4][:s]).to eq(1)
    end
  end

  describe 'calculate_connectors' do
    all = nil
    nid = nil
    before do
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.create!(id: 1, name: "2016-01", company_id: 1, timestamp: '2016-01-01 00:12:12')
      nid = NetworkName.find_or_create_by!(id: 1, name: "Communication Flow", company_id: 1).id

      FactoryGirl.create(:group, id: 11, name: 'g1')
      FactoryGirl.create(:group, id: 12, name: 'g2', parent_group_id: 11)
      FactoryGirl.create(:group, id: 13, name: 'g3', parent_group_id: 11)
      FactoryGirl.create(:group, id: 14, name: 'g4', parent_group_id: 11)
      FactoryGirl.create(:employee, id: 1, group_id: 11)
      FactoryGirl.create(:employee, id: 2, group_id: 11)
      FactoryGirl.create(:employee, id: 3, group_id: 12)
      FactoryGirl.create(:employee, id: 4, group_id: 12)
      FactoryGirl.create(:employee, id: 5, group_id: 12)
      FactoryGirl.create(:employee, id: 6, group_id: 13)
      FactoryGirl.create(:employee, id: 7, group_id: 14)
      FactoryGirl.create(:employee, id: 8, group_id: 14)
      FactoryGirl.create(:employee, id: 9, group_id: 14)
      FactoryGirl.create(:employee, id: 10,group_id: 14)

      all = [
        [0,1,1,0,0,0,0,0,0,0],
        [1,0,1,0,0,0,0,0,0,0],
        [1,1,0,1,0,0,0,0,0,0],
        [0,0,1,0,1,0,0,0,0,0],
        [0,0,0,1,0,1,1,1,1,1],
        [0,0,0,1,1,0,1,1,1,1],
        [0,0,0,0,1,1,0,1,1,1],
        [0,0,0,0,1,1,1,0,1,1],
        [0,0,0,0,1,1,1,1,0,1],
        [0,0,0,0,1,1,1,1,1,0]]
    end

    it 'result should be well formed' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      expect(res.length).to eq(10)
      expect(res.first[:id]).not_to be_nil
      expect(res.first[:measure]).not_to be_nil
    end

    it 'employee sending only to one group should get 0' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      id  = res[3][:id]
      mes = res[3][:measure]
      expect(id).to eq(4)
      expect(mes).to eq(0.0)
    end

    it 'sending to more groups results in higher scores' do
      fg_emails_from_matrix(all)
      res1 = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      all[0][8] = 1
      NetworkSnapshotData.delete_all
      fg_emails_from_matrix(all)
      res2 = AlgorithmsHelper.calculate_connectors(1, nid, 11)

      expect(res1[0][:measure]).to be < res2[0][:measure]
    end

    it 'less balanced traffic has lower score' do
      fg_emails_from_matrix(all)
      res1 = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      all[0][2] = 2
      NetworkSnapshotData.delete_all
      fg_emails_from_matrix(all)
      res2 = AlgorithmsHelper.calculate_connectors(1, nid, 11)

      expect(res1[0][:measure]).to be > res2[0][:measure]
    end

    it 'increasing overall traffic proportionally ...' do
      fg_emails_from_matrix(all)
      res1 = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      all[0][1] = 2
      all[0][2] = 2
      NetworkSnapshotData.delete_all
      fg_emails_from_matrix(all)
      res2 = AlgorithmsHelper.calculate_connectors(1, nid, 11)

      expect(res1[0][:measure]).to eq(res2[0][:measure])
    end
  end

  describe 'avg_number_of_recipients' do
    nid = nil
    before do
      Company.create!(id: 1, name: "Hevra10")
      Snapshot.create!(id: 1, name: "2016-01", company_id: 1, timestamp: '2016-01-01 00:12:12')
      nid = NetworkName.find_or_create_by!(id: 1, name: "Communication Flow", company_id: 1).id
      FactoryGirl.create(:employee, id: 1, group_id: 1, snapshot_id: 1)
      FactoryGirl.create(:employee, id: 2, group_id: 1, snapshot_id: 1)
      FactoryGirl.create(:employee, id: 3, group_id: 1, snapshot_id: 1)
      FactoryGirl.create(:employee, id: 4, group_id: 1, snapshot_id: 1)

      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 1, to_employee_id: 2, value: 1, message_id: "m1")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 1, to_employee_id: 3, value: 1, message_id: "m1")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 2, to_employee_id: 3, value: 1, message_id: "m2")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 2, to_employee_id: 4, value: 1, message_id: "m2")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 1, to_employee_id: 2, value: 1, message_id: "m3")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 1, to_employee_id: 3, value: 1, message_id: "m3")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 1, to_employee_id: 4, value: 1, message_id: "m3")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 3, to_employee_id: 4, value: 1, message_id: "m4")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 4, to_employee_id: 3, value: 1, message_id: "m5")
    end

    it 'should be lower than max' do
      res = AlgorithmsHelper.avg_number_of_recipients(1, -1, -1)
      emp1_score  = res.find {|e| e[:id] == 1}[:measure]
      expect(emp1_score).to be < 3
    end

    it 'should be higher than min' do
      res = AlgorithmsHelper.avg_number_of_recipients(1, -1, -1)
      emp1_score  = res.find {|e| e[:id] == 1}[:measure]
      expect(emp1_score).to be > 2
    end

    it 'should be higher with more emails' do
      res = AlgorithmsHelper.avg_number_of_recipients(1, -1, -1)
      emp2_score1  = res.find {|e| e[:id] == 2}[:measure]
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 2, to_employee_id: 1, value: 1, message_id: "m6")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 2, to_employee_id: 2, value: 1, message_id: "m6")
      NetworkSnapshotData.create!(snapshot_id: 1, network_id: nid, company_id: 1, from_employee_id: 2, to_employee_id: 3, value: 1, message_id: "m6")
      res = AlgorithmsHelper.avg_number_of_recipients(1, -1, -1)
      emp2_score2  = res.find {|e| e[:id] == 2}[:measure]
      expect(emp2_score1).to be < emp2_score2
    end

    it 'should give 0 for employee with no emails' do
      FactoryGirl.create(:employee, id: 5, group_id: 1, snapshot_id: 1)
      res = AlgorithmsHelper.avg_number_of_recipients(1, -1, -1)
      emp5_score  = res.find {|e| e[:id] == 5}[:measure]
      expect(emp5_score).to eq(0)
    end
  end
end
