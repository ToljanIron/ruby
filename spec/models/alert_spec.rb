require 'spec_helper'

SNAPSHOT_NAME1 = 'Jan/18'
SNAPSHOT_NAME2 = 'Feb/18'

describe Alert, type: :model do
  before do
    FactoryBot.create(:snapshot, id: 1, timestamp: DateTime.new(2018, 1, 1), company_id: 1)
    FactoryBot.create(:snapshot, id: 2, timestamp: DateTime.new(2018, 2, 1), company_id: 1)

    FactoryBot.create(:metric_name, id: 13, name: 'Test13')
    FactoryBot.create(:metric_name, id: 14, name: 'Test14')
    FactoryBot.create(:metric_name, id: 15, name: 'Test15')
    FactoryBot.create(:company_metric, id: 13, metric_id: 13)
    FactoryBot.create(:company_metric, id: 14, metric_id: 14)
    FactoryBot.create(:company_metric, id: 15, metric_id: 15)

    Alert.create!(company_id: 1, snapshot_id: 1, group_id: 2, alert_type: 1, company_metric_id: 13, state: 0)
    Alert.create!(company_id: 1, snapshot_id: 1, group_id: 3, alert_type: 1, company_metric_id: 15, state: 1)
    Alert.create!(company_id: 1, snapshot_id: 1, group_id: 4, alert_type: 1, company_metric_id: 13, state: 2)
    Alert.create!(company_id: 1, snapshot_id: 1, group_id: 4, alert_type: 1, company_metric_id: 13, state: 0)
    Alert.create!(company_id: 1, snapshot_id: 1, group_id: 5, alert_type: 1, company_metric_id: 13, state: 1)
    Alert.create!(company_id: 1, snapshot_id: 2, group_id: 2, alert_type: 2, company_metric_id: 13, state: 2)
    Alert.create!(company_id: 1, snapshot_id: 2, group_id: 3, alert_type: 1, company_metric_id: 13, state: 0)
    Alert.create!(company_id: 1, snapshot_id: 2, group_id: 4, alert_type: 1, company_metric_id: 14, state: 1)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  it 'should only get meetings that are pending from requested sid and gids' do
    ret = Alert.alerts_for_snapshot(1,SNAPSHOT_NAME1, [3, 4])
    expect(ret.length).to eq(1)
    expect(ret[0].metric_name).to start_with('Test')
    expect(ret[0].state).to satisfy { |value| value == 'pending' || value == 'viewed' }
  end

  it 'should all meetings from sid' do
    ret = Alert.alerts_for_snapshot(1,SNAPSHOT_NAME1)
    expect(ret.length).to eq(2)
  end

  it 'shoud mark alert as dicarded' do
    a = Alert.create!(company_id: 1, snapshot_id: 3, group_id: 5, alert_type: 1, company_metric_id: 13, state: 1)
    a.discard
    expect(a.state).to eq('discarded')
    a.delete
  end

  it 'shoud mark alert as viewed' do
    a = Alert.create!(company_id: 1, snapshot_id: 3, group_id: 5, alert_type: 1, company_metric_id: 13, state: 1)
    a.mark_viewed
    expect(a.state).to eq('viewed')
    a.delete
  end
end
