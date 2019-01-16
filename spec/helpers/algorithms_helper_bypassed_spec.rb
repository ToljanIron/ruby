require 'nmatrix'
require 'pp'
require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryBot::Syntax::Methods

include CompanyWithMetricsFactory

describe AlgorithmsHelper, type: :helper do
  describe 'bypassed managers' do
    res = nil

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryBot.reload
    end

    before do
      all = [
      #  1 2 3 4 5 6 7 8 9 10
        [0,2,1,4,1,5,1,0,0,1], # 1
        [0,0,0,3,0,0,3,2,0,0], # 2
        [1,1,0,3,3,2,1,0,1,0], # 3
        [3,2,4,0,2,2,0,0,0,0], # 4
        [2,1,1,0,0,0,0,0,0,0], # 5
        [4,4,0,2,0,0,0,0,0,0], # 6
        [1,3,1,0,0,0,0,0,0,0], # 7
        [0,0,0,0,0,0,0,0,0,0], # 8
        [0,0,0,1,0,0,0,0,0,0], # 9
        [0,0,0,0,0,0,0,0,0,2]] # 10
      fg_emails_from_matrix(all)

      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      NetworkName.find_or_create_by!(id: 1, name: "Communication Flow", company_id: 1)

      create_emps('moshe', 'acme.com', 10, {gid: 6})
      ###########################################################
      # 1 is the CEO. 2,3 and 4 are managers
      # 5,6,7,8,9 are employees
      ###########################################################
      managers = [
        [1,2],[1,3],[1,4],[2,5],[2,6],[3,7],[4,8],[4,9],[4,10]
      ]
      managers.each do |rel|
        EmployeeManagementRelation.create!(manager_id: rel[0], employee_id: rel[1], relation_type: 'recursive')
      end

      res = AlgorithmsHelper.most_bypassed_managers(1,1,-1,6)
    end

    it 'should rank managers by how much they are bypassed' do
      expect( res.f(2) ).to be < res.f(3)
      expect( res.f(2) ).to be < res.f(4)
      expect( res.f(3) ).to be < res.f(4)
    end

    it 'should be between 0 and 1' do
      res.each do |r|
        expect(r[:measure]).to be < 1
        expect(r[:measure]).to be > 0
      end
    end

    describe 'adding emails' do
      ids = []
      after do
        NetworkSnapshotData.where(id: ids).delete_all
      end

      it 'should decrease where there is one more email from employee to manager of manager' do
        ids << NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 5, to_employee_id: 1, value: 1).id
        ids << NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 5, to_employee_id: 1, value: 1).id
        res2 = AlgorithmsHelper.most_bypassed_managers(1,1,-1,6)
        expect( res2.f(2) ).to be < res.f(2)
      end

      it 'should decrease when peer sends more emails to employees' do
        ids << NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 2, to_employee_id: 8, value: 1).id
        ids << NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 2, to_employee_id: 9, value: 1).id
        res3 = AlgorithmsHelper.most_bypassed_managers(1,1,-1,6)
        expect( res3.f(4) ).to be < res.f(4)
      end
    end
  end

  class Array
    def f(eid)
      return self.select { |r| r[:id] == eid }.last[:measure]
    end
  end
end

