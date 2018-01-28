require 'spec_helper'
#require './spec/factories/company_factory.rb'
include SessionsHelper

describe GroupsController, type: :controller do

  before do
    log_in_with_dummy_user_with_role(1, 1)
    company = Company.create(name: 'some_name')
    Snapshot.create!(id: 1,company_id: 1, timestamp: 1.day.ago)
    @company_id = company.id
    Group.create(name: 'group_1', company_id: @company_id, snapshot_id: 1)
    Group.create(name: 'group_2', company_id: @company_id, snapshot_id: 1)
    Group.create(name: 'group_3', company_id: @company_id, parent_group_id: 2, snapshot_id: 1)
    Group.create(name: 'group_4', company_id: @company_id, parent_group_id: 2, snapshot_id: 1)
    Group.create(name: 'group_5', company_id: @company_id, parent_group_id: 4, snapshot_id: 1)
    Group.create(name: 'group_6', company_id: @company_id, snapshot_id: 1)
    Group.create(name: 'group_7', company_id: 2, snapshot_id: 1)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe ', groups' do
    def create_employees
      @employees_counters = { group_1: 0, group_2: 0, group_3: 0, group_4: 0, group_5: 0, group_6: 0 }
      (1..100).each do
        e = FactoryGirl.create(:employee, company_id: @company_id)
        r = rand(1..6)
        e.group_id = r
        @employees_counters["group_#{r}".to_sym] += 1
        e.save!
      end
    end

    before do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
      create_employees
      log_in_with_dummy_user
      tmp = http_get_with_jwt_token(:groups)
      tmp = JSON.parse tmp.body
      @groups = tmp['groups']
    end

    it ', should return same amount of groups' do
      expect(@groups.count).to eq(6)
    end
  end
end
