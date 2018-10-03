require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/create_analyze_historical_data_helper.rb'

describe AnalyzeHistoricalDataHelper, type:  :helper do
  before do
    FactoryGirl.create(:company)
    FactoryGirl.create(:snapshot, timestamp: 4.months.ago)
    NetworkName.create!(company_id: 1, name: 'Communication Flow')
    PushProc.create!(company_id: 1)

    ## Create metrics and algorithms
    AlgorithmType.find_or_create_by!(id: 1, name: 'measure')
    Algorithm.find_or_create_by!(id: 700, name: 'spammers_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
    spammers_id = MetricName.find_or_create_by!(name: 'Spammers', company_id: 1).id
    CompanyMetric.find_or_create_by!(metric_id: spammers_id, network_id: -1, company_id: 1, algorithm_id: 700, algorithm_type_id: 1)
    Algorithm.find_or_create_by!(id: 701, name: 'blitzed_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
    blitzed_id  = MetricName.find_or_create_by!(name: 'Blitzed', company_id: 1).id
    CompanyMetric.find_or_create_by!(metric_id: blitzed_id, network_id: -1, company_id: 1, algorithm_id: 701, algorithm_type_id: 1)

    ## Create groups and employees
    FactoryGirl.create(:group)
    FactoryGirl.create(:group)
    Group.find(1).update(hierarchy_size: 3, nsleft: 1, nsright: 4)
    Group.find(2).update(parent_group_id: 1, hierarchy_size: 2, nsleft: 2, nsright: 3)

    FactoryGirl.create(:employee, email: 'emp1@acme.com',group_id: 1)
    FactoryGirl.create(:employee, email: 'emp2@acme.com',group_id: 2)
    FactoryGirl.create(:employee, email: 'emp3@acme.com',group_id: 2)

    ## Create raw entries
    dates = [Time.now, 1.month.ago, 2.month.ago]
    dates.each do |date|
      FactoryGirl.create(:raw_data_entry, from: 'emp1@acme.com', to: ['emp2@acme.com'], date: date)
      FactoryGirl.create(:raw_data_entry, from: 'emp1@acme.com', to: ['emp3@acme.com'], date: date)
      FactoryGirl.create(:raw_data_entry, from: 'emp2@acme.com', to: ['emp1@acme.com'], date: date)
    end
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  it 'should work' do
    AnalyzeHistoricalDataHelper.run(1)
    expect( RawDataEntry.where(processed: false).count ).to eq(0)
    expect( Snapshot.count ).to eq(4)
    expect( CdsMetricScore.count ).to be > 0
    pp = PushProc.last
    expect( pp.state ).to eq('done')
    expect( pp.num_snapshots ).to eq(9)
    expect( pp.num_snapshots_created ).to eq(3)
    expect( pp.num_snapshots_processed ).to eq(3)
  end

  it 'should not fail if there are no rdes' do
    RawDataEntry.delete_all
    expect { AnalyzeHistoricalDataHelper.run(1) }.not_to raise_error
    expect( PushProc.last.state ).to eq('done')
  end
end
