require 'spec_helper'

describe BackendVTwoHelper, type: :helper do
  describe 'company_reset' do
    before do
      Company.create!(id: 2, name: "testcom")
      Snapshot.create!(id: 45, name: "2015-05", snapshot_type: 3, company_id: 2, timestamp: 3.weeks.ago)
      Snapshot.create!(id: 46, name: "2015-06", snapshot_type: 3, company_id: 2, timestamp: 2.weeks.ago)
      Snapshot.create!(id: 47, name: "2015-07", snapshot_type: 3, company_id: 2, timestamp: 1.week.ago)

      Group.create!(id: 28, name: "CS",  company_id: 2, parent_group_id: nil)
      Group.create!(id: 29, name: "CS1", company_id: 2, parent_group_id: 28)
      Group.create!(id: 33, name: "CS2", company_id: 2, parent_group_id: 28)
      Group.create!(id: 34, name: "CS4", company_id: 4, parent_group_id: nil)

      Employee.create!(id: 1, company_id: 2, email: "pete1@sala.com", external_id: "11", first_name: "Dave1", last_name: "sala", group_id: 28)
      Employee.create!(id: 2, company_id: 2, email: "pete2@sala.com", external_id: "12", first_name: "Dave2", last_name: "sala", group_id: 29)
      Employee.create!(id: 3, company_id: 2, email: "pete3@sala.com", external_id: "13", first_name: "Dave3", last_name: "sala", group_id: 33)
      Employee.create!(id: 4, company_id: 2, email: "pete4@sala.com", external_id: "14", first_name: "Dave4", last_name: "sala", group_id: 33)
      Employee.create!(id: 9, company_id: 9, email: "pete9@sala.com", external_id: "14", first_name: "Dave4", last_name: "sala", group_id: 33)

      EmployeeManagementRelation.create!(manager_id: 1, employee_id: 2, relation_type: 1)
      EmployeeManagementRelation.create!(manager_id: 1, employee_id: 3, relation_type: 1)
      EmployeeManagementRelation.create!(manager_id: 1, employee_id: 4, relation_type: 1)
      EmployeeManagementRelation.create!(manager_id: 21, employee_id: 22, relation_type: 1)

      NetworkSnapshotData.create_email_adapter(employee_from_id: 3, employee_to_id: 4, company_id: 2, snapshot_id: 47, weight: 0, n1: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 2, employee_to_id: 4, company_id: 2, snapshot_id: 47, weight: 0, n1: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 4, company_id: 2, snapshot_id: 47, weight: 0, n1: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 4, company_id: 2, snapshot_id: 46, weight: 0, n1: 1)
      NetworkSnapshotData.create_email_adapter(employee_from_id: 5, employee_to_id: 4, company_id: 2, snapshot_id: 46, weight: 0, n1: 1)

      NetworkSnapshotData.create!(snapshot_id: 47, network_id: 1, company_id: 2, from_employee_id: 1, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 47, network_id: 1, company_id: 2, from_employee_id: 1, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 46, network_id: 1, company_id: 2, from_employee_id: 5, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 46, network_id: 1, company_id: 2, from_employee_id: 4, to_employee_id: 2, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 47, network_id: 2, company_id: 2, from_employee_id: 1, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 47, network_id: 2, company_id: 2, from_employee_id: 1, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 46, network_id: 2, company_id: 2, from_employee_id: 5, to_employee_id: 4, value: 1)
      NetworkSnapshotData.create!(snapshot_id: 46, network_id: 2, company_id: 2, from_employee_id: 4, to_employee_id: 2, value: 1)

    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should remove all snapshots and employee related data' do
      BackendVTwoHelper.company_reset(2)
      expect(EmployeeManagementRelation.count).to eq(4)
      expect(Employee.count).to eq(5)
      expect(Group.count).to eq(4)
      expect(Company.count).to eq(1)
      expect(NetworkSnapshotData.count).to eq(6)
      expect(Snapshot.count).to eq(3)

    end

  end
end
