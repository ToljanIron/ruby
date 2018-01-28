require 'spec_helper'
include SessionsHelper

describe AlertsController, type: :controller do

  before do
    log_in_with_dummy_user
    FactoryGirl.create(:metric_name, id: 13, name: 'Test13')
    FactoryGirl.create(:company_metric, id: 13, metric_id: 13)

    Alert.create!(id: 111, company_id: 1, snapshot_id: 1, group_id: 2, alert_type: 1, company_metric_id: 13, state: 0)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'get_alerts' do
    it 'should return one alert' do
      tmp = http_get_with_jwt_token(:get_alerts, {sid: 1})
      ret = JSON.parse tmp.body
      expect(ret.count).to be > 0
    end

    it 'should return one alert with gids specified' do
      tmp = http_get_with_jwt_token(:get_alerts, {sid: 1, gids: '2,3'})
      ret = JSON.parse tmp.body
      expect(ret.count).to be > 0
    end

    it 'should return nothing if gids are wrong' do
      tmp = http_get_with_jwt_token(:get_alerts, {sid: 1, gids: '3'})
      ret = JSON.parse tmp.body
      expect(ret.count).to eq(0)
    end
  end

  describe 'discard_alerts' do
    it 'should discard the alert' do
      http_post_with_jwt_token(:discard_alerts, {alids: '111'})
      expect(Alert.first.state).to eq('discarded')
    end

    it 'should not discard an alert that belongs to a different company' do
      Alert.create!(id: 112, company_id: 2, snapshot_id: 1, group_id: 2, alert_type: 1, company_metric_id: 13, state: 0)
      http_post_with_jwt_token(:discard_alerts, {alids: '112'})
      expect(Alert.last.state).not_to eq('discarded')
    end
  end
end
