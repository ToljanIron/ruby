# frozen_string_literal: true
require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryGirl::Syntax::Methods

describe InteractAlgorithmsHelper, type: :helper do
  before(:each) do
    Company.create!(id: 1, name: 'testcom', randomize_image: true, active: true)
    snapshot_factory_create(id: 45, name: '2015-06', snapshot_type: 3, company_id: 2)
    Group.create!(id: 3, name: 'Testcom', company_id: 1, parent_group_id: nil)
    Group.create!(id: 4, name: 'QA',      company_id: 1, parent_group_id: 3)
    Employee.create!(id: 1, company_id: 1, email: 'pete1@sala.com', external_id: '11', first_name: 'Dave1', last_name: 'sala', group_id: 3)
    Employee.create!(id: 2, company_id: 1, email: 'pete2@sala.com', external_id: '12', first_name: 'Dave2', last_name: 'sala', group_id: 3)
    Employee.create!(id: 3, company_id: 1, email: 'pete3@sala.com', external_id: '13', first_name: 'Dave3', last_name: 'sala', group_id: 4)
    Employee.create!(id: 4, company_id: 1, email: 'pete4@sala.com', external_id: '14', first_name: 'Dave4', last_name: 'sala', group_id: 4)
    NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
    NetworkName.create!(id: 2, name: 'Stam',   company_id: 1)

    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 1, to_employee_id: 3, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 3, to_employee_id: 2, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 3, to_employee_id: 4, value: 1)

    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 1, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 2, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 3, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 2, to_employee_id: 4, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 1, to_employee_id: 3, value: 1)
  end

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'calculate_network_indegree' do

    it 'should create correct number of records' do
      res = calculate_network_indegree(1, 45, 1, 3)
      expect( res.count ).to eq(Employee.count)
    end

  end

end
