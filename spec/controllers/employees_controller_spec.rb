require 'spec_helper'
#require './spec/factories/company_factory.rb'
include SessionsHelper

describe EmployeesController, type: :controller do
  describe ', list employees' do
    before do
      create_companies_data
    end
    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should return only employees from logged in user company' do
      log_in_with_dummy_user_with_role(1, 2)
      res = get :list_employees
      res = JSON.parse res.body
      res = res['employees']
      expect(res[0]['company_id']).to eq(2)
      expect(res.length).to eq(5)
    end

    it 'should return no employees when the user to company with no employees' do
      log_in_with_dummy_user_with_role(1, 5)
      res = get :list_employees
      res = JSON.parse res.body
      res = res['employees']
      expect(res.length).to eq(0)
    end
  end

  describe ', list managers' do
    before do
      create_companies_data
      EmployeeManagementRelation.create!(manager_id: 1, employee_id: 3,  relation_type: :direct)
      EmployeeManagementRelation.create!(manager_id: 1, employee_id: 6,  relation_type: :direct)
      EmployeeManagementRelation.create!(manager_id: 1, employee_id: 9,  relation_type: :direct)
      EmployeeManagementRelation.create!(manager_id: 1, employee_id: 12, relation_type: :direct)
      EmployeeManagementRelation.create!(manager_id: 1, employee_id: 15, relation_type: :professional)
      EmployeeManagementRelation.create!(manager_id: 2, employee_id: 4, relation_type: :direct)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'Should return a result of length 4' do
      log_in_with_dummy_user_with_role(1, 2)
      res = get :list_managers
      res = JSON.parse res.body
      res = res['managers']
      expect(res.length).to eq(4)
    end

    it 'Empty result with user which with no entries' do
      log_in_with_dummy_user_with_role(1, 4)
      res = get :list_managers
      res = get :list_managers
      res = JSON.parse res.body
      res = res['managers']
      expect(res.length).to eq(0)
    end
  end
end
