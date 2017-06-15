require 'spec_helper'
#require './spec/factories/company_factory.rb'
include SessionsHelper

describe SnapshotsController, type: :controller do
  before do
    # login with hr user
    log_in_with_dummy_user_with_role(1, 3)
    create_companies_data
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe ', get_snapshots' do
    it 'should return array of size 2 as json' do
      res = get :list_snapshots
      res = JSON.parse res.body
      res = res['snapshots']
      expect(res.length).to eq(2)
    end

    it 'json should contain id object' do
      res = get :list_snapshots
      res = JSON.parse res.body
      res = res['snapshots']
      expect(res[0]['id']).not_to be_nil
    end

    it 'json should contain date object' do
      res = get :list_snapshots
      res = JSON.parse res.body
      res = res['snapshots']
      expect(res[0]['date']).not_to be_nil
    end
  end

  describe 'Test permissions' do
    before do
      DatabaseCleaner.clean_with(:truncation)
      create_companies_data
    end
    it 'Permitted user with only 1 snapshot gets exactly 1 snapshot' do
      # login with hr user
      log_in_with_dummy_user_with_role(1, 2)
      res = get :list_snapshots
      res = JSON.parse res.body
      res = res['snapshots']
      expect(res.length).to eq(1)
    end
  end
end
