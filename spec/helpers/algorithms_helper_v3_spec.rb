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
end


