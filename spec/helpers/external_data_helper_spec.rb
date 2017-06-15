require 'spec_helper'
require './spec/spec_factory'

include CompanyWithMetricsFactory

def mock_external_data_list(metric_name, number_of_score = -1, id = nil)
  res = {}
  score_list = []
  (0..number_of_score).each { score_list.push(mock_score_list) }
  if id
    res = { 'score_list' => score_list, 'metric_name' => metric_name, 'id' => id }
  else
    res = { 'score_list' => score_list, 'metric_name' => metric_name }
  end
  return res
end

def mock_score_list
  return { 'snapshot_id' => rand(1..100), 'score' => rand(1..100_000) }
end
describe ExternalDataHelper, type: :helper do
  before do
    #CompanyWithMetricsFactory.create_company
    create_company
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end
  describe ',get_external_data' do
    it ', should retrun []  if is empty metrics' do
      res =  get_external_data(1)
      expect(res).to eq([])
    end
    it ', should return the metrics with the score list only 1 for company_id 2' do
      @metric1 = FactoryGirl.create(:external_data_metric, external_metric_name: 'linie')
      create_score(@metric1.id, 1, 5)
      create_score(@metric1.id, 2, 2.5)
      @metric2 = FactoryGirl.create(:external_data_metric, external_metric_name: 'PPP', company_id: 3)
      create_score(@metric2.id, 5, 7.5)
      res =  get_external_data(@metric1.company_id)
      expect(res.length).to eq(1)
    end
    it ', should return 1 metrics when the last metric is empty'do
      @metric1 = FactoryGirl.create(:external_data_metric, external_metric_name: 'linie')
      @metric2 = FactoryGirl.create(:external_data_metric, external_metric_name: '2line')
      create_score(@metric2.id, 10, 5)
      res =  get_external_data(@metric2.company_id)
      expect(res.length).to eq(1)
    end
    it ', should return 2 metrics' do
      @metric1 = FactoryGirl.create(:external_data_metric, external_metric_name: 'linie')
      @metric2 = FactoryGirl.create(:external_data_metric, external_metric_name: '2line')
      create_score(@metric2.id, 10, 5)
      create_score(@metric1.id, 10, 5)
      create_score(@metric1.id, 10, 5)
      res =  get_external_data(@metric1.company_id)
      expect(res.length).to eq(2)
    end
  end

  describe ', #save_external_data' do
    before do
      @metric1 = FactoryGirl.create(:external_data_metric, external_metric_name: 'linie')
      @metric2 = FactoryGirl.create(:external_data_metric, external_metric_name: '2line')
    end

    it ', should save or updated the external_data if there is combintation' do
      external_data_list = []
      external_data_list.push(mock_external_data_list('Metric1', 5, 1))
      external_data_list.push(mock_external_data_list('Metric2', 3, 2))
      data = { 'external_data_list' => external_data_list, 'remove_list' => [] }
      save_external_data(data, @metric1.company_id)
      expect(ExternalDataMetric.all.count).to eq(2)
      expect(ExternalDataMetric.find_by_id(@metric1).external_metric_name).to eq('Metric1')
    end

    it ',should save a new external_metric_data and also update 2 metrics' do
      external_data_list = []
      external_data_list.push(mock_external_data_list('Metric1', 5, 1))
      external_data_list.push(mock_external_data_list('Metric2', 3, 2))
      external_data_list.push(mock_external_data_list('new-Metric', 2))
      data = { 'external_data_list' => external_data_list, 'remove_list' => [] }
      save_external_data(data, @metric1.company_id)
      expect(ExternalDataMetric.all.count).to eq(3)
      expect(ExternalDataMetric.where(external_metric_name: 'new-Metric').first.nil?).to be(false)
      expect(ExternalDataScore.where(external_data_metric_id: 3).count).to eq(3)
    end

    it ',should not save the new metric beacuse without score list' do
      external_data_list = []
      external_data_list.push(mock_external_data_list('Metric1', 5, 1))
      external_data_list.push(mock_external_data_list(''))
      data = { 'external_data_list' => external_data_list, 'remove_list' => [] }
      save_external_data(data, @metric1.company_id)
      expect(ExternalDataMetric.all.count).to eq(2)
      expect(ExternalDataMetric.where(external_metric_name: '').first.nil?).to be(true)
    end

    it ',should not save the new metric beacuse without score list' do
      external_data_list = []
      external_data_list.push(mock_external_data_list('Metric1', 5, 1))
      external_data_list.push(mock_external_data_list('MMMM'))
      data = { 'external_data_list' => external_data_list, 'remove_list' => [] }
      save_external_data(data, @metric1.company_id)
      expect(ExternalDataMetric.all.count).to eq(2)
      expect(ExternalDataMetric.where(external_metric_name: 'MMMM').first.nil?).to be(true)
    end
  end
end
