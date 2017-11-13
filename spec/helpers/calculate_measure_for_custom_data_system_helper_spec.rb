# frozen_string_literal: true
require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'

include CompanyWithMetricsFactory
def create_measure_data(score_number)
  res = {}
  res[:dt] = Time.now.to_i
  res[:date] = 'no no'
  res[:measure_name] = 'Metric 1'
  res[:measure_id] = 1
  res[:degree_list] = add_score_list(score_number)
  return res
end

def add_score_list(index)
  res = []
  (0..index).each do |i|
    res.push(rate: i + 5, id: i)
  end
  return res
end

describe CalculateMeasureForCustomDataSystemHelper, type: :helper do
  before do
    Company.create(id: 0, name: 'company0')

    CompanyWithMetricsFactory.create_metrics
    CompanyWithMetricsFactory.create_algorithms_and_algorithm_type
    CompanyWithMetricsFactory.create_company_metrics_company_0
    CompanyWithMetricsFactory.create_company_metrics_company_1
    CompanyWithMetricsFactory.create_company_metrics_company_2
    CompanyWithMetricsFactory.create_network_names
    CompanyWithMetricsFactory.create_metric_names

    Rake::Task['db:seed:event_types'].reenable
    Rake::Task['db:seed:event_types'].invoke
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
    Rake::Task['db:precalculate_metric_scores_for_custom_data_system'].reenable
  end

  describe 'calculate standard deviation' do
    describe 'when 2 snapshots with same employees' do
      before do
        @prev_snapshot = [{ id: 1, measure: 0, rate: 100 }, { id: 3, measure: 3.33, rate: 33 }, { id: 2, measure: 3.33, rate: 33 }]
        @current_snapshot = [{ id: 3, measure: 5, rate: 100 }, { id: 2, measure: 8, rate: 100 }, { id: 1, measure: 10.0, rate: 100 }]
      end

      after do
        DatabaseCleaner.clean_with(:truncation)
        FactoryGirl.reload
        Rake::Task['db:precalculate_metric_scores_for_custom_data_system'].reenable
      end

      it 'should return standard deviation' do
        res = calculate_sd(@prev_snapshot, @current_snapshot)
        res.select { |emp| emp[:id] == 2 }.first.should include(pay_attention_flag: false)
        res.select { |emp| emp[:id] == 3 }.first.should include(pay_attention_flag: false)
      end
    end

    describe 'when 2 snapshots have different employees' do
      before do
        @prev_snapshot = [{ id: 1, measure: 0, rate: 100 }]
        @current_snapshot = [{ id: 3, measure: 3.33, rate: 33 }]
      end

      after do
        DatabaseCleaner.clean_with(:truncation)
        FactoryGirl.reload
        Rake::Task['db:precalculate_metric_scores_for_custom_data_system'].reenable
      end

      it 'should return nil if a snaphot is empty' do
        res = calculate_sd(@prev_snapshot, @current_snapshot)
        expect(res).to eq(nil)
      end
    end

    describe 'when one of the sshots is empty ' do
      before do
        @prev_snapshot = []
        @current_snapshot = [{ id: 3, measure: 3.33, rate: 33 }]
      end

      after do
        DatabaseCleaner.clean_with(:truncation)
        FactoryGirl.reload
        Rake::Task['db:precalculate_metric_scores_for_custom_data_system'].reenable
      end

      it 'should return nil if a snaphot is empty' do
        res = calculate_sd(@prev_snapshot, @current_snapshot)
        expect(res).to eq(nil)
      end
    end
  end

  describe 'empty snapshots in metric' do
    it 'should return true when all snapshots are empty' do
      snapshots_list = { '3': [], '4': [] }
      res = empty_snapshots?(snapshots_list)
      res.should == true
    end

    it 'should return false when 1 snapshots is not empty' do
      snapshots_list = { '3': [], '4': [{ id: 1, measure: 2 }], '5': [] }
      res = empty_snapshots?(snapshots_list)
      res.should == false
    end
  end

  describe 'cds_get_group_measure_data' do
    before do
      @most_isolated = 22
      FactoryGirl.create(:group, id: 1, name: 'group')
      FactoryGirl.create(:group, id: 2, name: 'subgroup1', parent_group_id: 1)
      FactoryGirl.create(:group, id: 3, name: 'subgroup2', parent_group_id: 1)
      CdsMetricScore.create(company_id: 1, subgroup_id: 1, snapshot_id: 1, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 2, snapshot_id: 1, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 2, group_id: 1, snapshot_id: 1, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 3, snapshot_id: 1, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 3, group_id: 1, snapshot_id: 1, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 1, snapshot_id: 2, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 2, snapshot_id: 2, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 2, group_id: 1, snapshot_id: 2, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 3, snapshot_id: 2, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      CdsMetricScore.create(company_id: 1, subgroup_id: 3, group_id: 1, snapshot_id: 2, employee_id: 0, algorithm_id: @most_isolated, score: 1.00, company_metric_id: 0)
      FactoryGirl.create(:snapshot, id: 1, snapshot_type: nil)
      FactoryGirl.create(:snapshot, id: 2, snapshot_type: nil)
      @cm = CompanyMetric.where(algorithm_id: @most_isolated).first
      @result = cds_get_group_measure_data(1, 1, @cm)
    end

    it 'should return data on each snapshot for specified algorithm' do
      expect(@result[:snapshots].length).to eq 2
    end

    it 'should return data on each subgroup within the snapshot' do
      expect(@result[:snapshots].values[0].length).to eq 2
    end

    it 'should return the corresponding measure name' do
      expect(@result[:graph_data][:measure_name]).to eq MetricName.find(@cm.metric_id).name
    end

    it 'should return average values for graph per snapshot' do
      expect(@result[:graph_data][:data][:values].length).to eq 2
    end
  end

  describe 'cds_get_network_relations_data' do
    before do
      Snapshot.create(company_id: 0, timestamp: Time.zone.now, snapshot_type: 1)
      FactoryGirl.create(:group, company_id: 0)
      FactoryGirl.create_list(:group_employee, 4, company_id: 0)
    end

    it 'should return hash even if data on networks is empty, but with no communication flow' do
      result = cds_get_network_relations_data(0, -1, 1, 1)
      expect(result.length).to equal 3
      expect(result[0][:relation]).to be_empty
      expect(result[5][:relation]).to be_empty
      expect(result[8][:relation]).to be_empty
    end
  end

  describe 'cds_show_network_and_metric_names' do
    before do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.create(:network_name, id: 1, name: 'Friendship', company_id: 1)
      FactoryGirl.create(:network_name, id: 2, name: 'Advice', company_id: 1)
      FactoryGirl.create(:network_name, id: 3, name: 'Trust', company_id: 1)
      FactoryGirl.create(:network_name, id: 4, name: 'most brave', company_id: 1)
      FactoryGirl.create(:network_name, id: 5, name: 'communication flow', company_id: 1)

      FactoryGirl.create(:metric_name, id: 28, name: 'popular', company_id: 1)
      FactoryGirl.create(:metric_name, id: 29, name: 'super', company_id: 1)
      FactoryGirl.create(:metric_name, id: 30, name: 'van goach', company_id: 1)
      FactoryGirl.create(:metric_name, id: 31, name: 'advice in', company_id: 1)
      FactoryGirl.create(:metric_name, id: 32, name: 'advice out', company_id: 1)
      FactoryGirl.create(:metric_name, id: 33, name: 'trusted', company_id: 1)
      FactoryGirl.create(:metric_name, id: 34, name: 'bla', company_id: 1)
      FactoryGirl.create(:metric_name, id: 35, name: 'brave in algorithm', company_id: 1)

      FactoryGirl.create(:metric_name, id: 36, name: 'advice out', company_id: 2)
      FactoryGirl.create(:metric_name, id: 37, name: 'collaboration', company_id: 1)

      FactoryGirl.create(:company_metric, id: 233, metric_id: 28, network_id: 1, company_id: 1, algorithm_id: 28, algorithm_type_id: 3)
      FactoryGirl.create(:company_metric, id: 230, metric_id: 29, network_id: 1, company_id: 1, algorithm_id: 27, algorithm_type_id: 3)
      FactoryGirl.create(:company_metric, id: 203, metric_id: 30, network_id: 1, company_id: 1, algorithm_id: 3, algorithm_type_id: 3)
      FactoryGirl.create(:company_metric, id: 206, metric_id: 31, network_id: 3, company_id: 1, algorithm_id: 7, algorithm_type_id: 3)
      FactoryGirl.create(:company_metric, id: 208, metric_id: 32, network_id: 2, company_id: 1, algorithm_id: 14, algorithm_type_id: 3)
      FactoryGirl.create(:company_metric, id: 209, metric_id: 33, network_id: 2, company_id: 1, algorithm_id: 15, algorithm_type_id: 3)
      FactoryGirl.create(:company_metric, id: 210, metric_id: 34, network_id: 4, company_id: 1, algorithm_id: 12, algorithm_type_id: 3)
      FactoryGirl.create(:company_metric, id: 211, metric_id: 35, network_id: 4, company_id: 1, algorithm_id: 13, algorithm_type_id: 3)
    end

    it 'should return array of arrays describing the hirarchy of the networks-metric names' do
      res = cds_get_network_and_metric_names(1, 3)
      res['Friendship'] = res['Friendship'].sort
      res['Trust'] = res['Trust'].sort
      res['Advice'] = res['Advice'].sort
      res['most brave'] = res['most brave'].sort
      expect(res).to eq('Friendship' => ['popular', 'super', 'van goach'], 'Trust' => ['advice in'], 'Advice' => ['advice out', 'trusted'], 'most brave' => ['bla', 'brave in algorithm'])
    end

    it 'should return only the network from company metric and not include metric/networks that not mapped' do
      res = cds_get_network_and_metric_names(1, 3)
      expect(res.keys).not_to include('communication flow')
      expect(res.values.flatten).not_to include('collaboration')
    end

    it 'should return [] when not have a company metrics' do
      res = cds_get_network_and_metric_names(2, 3)
      expect(res).to eq({})
    end
  end

  describe 'calculate_and_save_gauge_parameters' do
    before do
      DatabaseCleaner.clean_with(:truncation)
      @gc = GaugeConfiguration.create!(minimum_value: -1, maximum_value: -1, minimum_area: -1, maximum_area: -1, company_id: 9)
      @cm = CompanyMetric.create!(company_id: 1, algorithm_id: 1, gauge_id: @gc.id, algorithm_type_id: 1, network_id: 17)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 1, employee_id: -1, group_id: 1, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 2, employee_id: -1, group_id: 2, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 3, employee_id: -1, group_id: 3, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 4, employee_id: -1, group_id: 4, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 5, employee_id: -1, group_id: 5, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 6, employee_id: -1, group_id: 6, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 7, employee_id: -1, group_id: 7, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 8, employee_id: -1, group_id: 8, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 9, employee_id: -1, group_id: 9, company_metric_id: @cm.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 1, snapshot_id: 1, score: 10, employee_id: -1, group_id: 10, company_metric_id: @cm.id)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should save new parameters in database' do
      calculate_and_save_gauge_parameters(1, 1, 1, @cm)
      gc = GaugeConfiguration.find(@gc.id)
      expect(gc.minimum_value).to eq(1.0)
      expect(gc.maximum_value).to eq(10.0)
      expect(gc.minimum_area).to eq(3.0)
      expect(gc.maximum_area).to eq(8.0)
    end

    it 'should re-calcuate the params according to preset values' do
      @gc.update(static_minimum: -1)
      @gc.update(static_maximum: 1)
      calculate_and_save_gauge_parameters(1, 1, 1, @cm)
      gc = GaugeConfiguration.find(@gc.id)
      expect(gc.minimum_value).to eq(-1.0)
      expect(gc.maximum_value).to eq(1.0)
      expect(gc.minimum_area.to_f).to eq(-0.56)
      expect(gc.maximum_area.to_f).to eq(0.56)
    end
  end

  describe 'get_network_list_to_compay_mertic' do
    it 'should get the network_list from the compay metric row with 3 networks' do
      cm = FactoryGirl.create(:company_metric, id: 500, metric_id: 28, network_id: 1, company_id: 1, algorithm_id: 28, algorithm_type_id: 3, algorithm_params: '{"network_b_id": 12, "network_c_id": 4}')
      netwotk_list = get_network_list_to_compay_mertic(cm)
      expect(netwotk_list.length).to eq(3)
    end

    it 'should get the network_list with only 1 network' do
      cm = FactoryGirl.create(:company_metric, id: 501, metric_id: 28, network_id: 1, company_id: 1, algorithm_id: 28, algorithm_type_id: 3)
      netwotk_list = get_network_list_to_compay_mertic(cm)
      expect(netwotk_list.length).to eq(1)
    end
  end
end

describe CalculateMeasureForCustomDataSystemHelper, type: :helper do
  describe 'Optimize cds_get_measure_data' do
    before do
      Company.create(id: 1, name: 'Acme')
      FactoryGirl.create(:snapshot, id: 1, snapshot_type: nil)
      FactoryGirl.create(:snapshot, id: 2, snapshot_type: nil)
      AlgorithmType.create(id: 1, name: 'measure')
      FactoryGirl.create(:metric, name: 'Happy', metric_type: 'measure', index: 1)
      FactoryGirl.create(:metric, name: 'Funny', metric_type: 'measure', index: 4)
      FactoryGirl.create(:algorithm, id: 28, name: 'happy', algorithm_type_id: 1, algorithm_flow_id: 1)
      FactoryGirl.create(:algorithm, id: 29, name: 'funny', algorithm_type_id: 1, algorithm_flow_id: 1)
      CompanyWithMetricsFactory.create_network_names
      FactoryGirl.create(:metric_name, id: 1, name: 'Happy', company_id: 1)
      FactoryGirl.create(:metric_name, id: 2, name: 'Funny', company_id: 1)

      FactoryGirl.create(:company_metric, id: 7, metric_id: 1, network_id: 3, company_id: 1, algorithm_id: 28, algorithm_type_id: 1)
      FactoryGirl.create(:company_metric, id: 8, metric_id: 2, network_id: 3, company_id: 1, algorithm_id: 29, algorithm_type_id: 1)

      @g1 = FactoryGirl.create(:group, name: 'group_1', company_id: 1).id
      @g2 = FactoryGirl.create(:group, name: 'group_1', company_id: 1, parent_group_id: @g1).id

      @emp1 = FactoryGirl.create(:employee, email: 'email1@mail.com', group_id: @g1, company_id: 1).id
      @emp2 = FactoryGirl.create(:employee, email: 'email2@mail.com', group_id: @g1, company_id: 1).id
      @emp3 = FactoryGirl.create(:employee, email: 'email3@mail.com', group_id: @g1, company_id: 1).id
      @emp4 = FactoryGirl.create(:employee, email: 'email4@mail.com', group_id: @g2, company_id: 1).id
      @emp5 = FactoryGirl.create(:employee, email: 'email5@mail.com', group_id: @g2, company_id: 1).id

      ## At long last we can fill cds_metric_scores
      ## Groups data
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 1, employee_id: @emp1, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 2, employee_id: @emp2, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 3, employee_id: @emp3, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 4, employee_id: @emp4, group_id: @g2, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 5, employee_id: @emp5, group_id: @g2, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 2, employee_id: @emp1, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 3, employee_id: @emp2, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 4, employee_id: @emp3, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 5, employee_id: @emp4, group_id: @g2, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 6, employee_id: @emp5, group_id: @g2, company_metric_id: 7, company_id: 1)

      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 1, employee_id: @emp1, group_id: @g1, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 2, employee_id: @emp2, group_id: @g1, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 3, employee_id: @emp3, group_id: @g1, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 4, employee_id: @emp4, group_id: @g2, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 5, employee_id: @emp5, group_id: @g2, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 2, employee_id: @emp1, group_id: @g1, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 3, employee_id: @emp2, group_id: @g1, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 4, employee_id: @emp3, group_id: @g1, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 5, employee_id: @emp4, group_id: @g2, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 6, employee_id: @emp5, group_id: @g2, company_metric_id: 8, company_id: 1)

      ## Company wide data
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 11, employee_id: @emp1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 12, employee_id: @emp2, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 13, employee_id: @emp3, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 14, employee_id: @emp4, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 1, score: 15, employee_id: @emp5, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 12, employee_id: @emp1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 13, employee_id: @emp2, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 14, employee_id: @emp3, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 15, employee_id: @emp4, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 28, snapshot_id: 2, score: 16, employee_id: @emp5, company_metric_id: 7, company_id: 1)

      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 21, employee_id: @emp1, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 22, employee_id: @emp2, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 23, employee_id: @emp3, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 24, employee_id: @emp4, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 1, score: 25, employee_id: @emp5, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 32, employee_id: @emp1, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 33, employee_id: @emp2, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 34, employee_id: @emp3, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 35, employee_id: @emp4, company_metric_id: 8, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 29, snapshot_id: 2, score: 36, employee_id: @emp5, company_metric_id: 8, company_id: 1)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'should adher to a specific data strucutre' do
      res = cds_get_measure_data(1, -1, [29, 28], @g2)
      expect(res.count).to eq(2)
    end

    it 'should work for entire company' do
      res = cds_get_measure_data(1, -1, [29, 28], @g1)
      expect(res.count).to eq(2)
    end
  end

  describe 'get_emails_scores_from_helper' do
    before do
      generate_data_for_acme
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    describe 'calculate_group_top_scores' do
      it 'calculate_top_scores should return a list of groups when given group_id' do
        res = calculate_group_top_scores(1, 2, [@g3, @g4], [701, 702])
        expect(res.length).to eq(2)
      end

      it 'calculate_top_scores should return a list of groups when given algorithm_id' do
        res = calculate_group_top_scores(1, 2, [@g3, @g4], [701, 702])
        expect(res.length).to eq(2)
        expect(res[0]).to eq(4)
      end
    end

    it 'should work with group_id' do
      res = get_email_scores_from_helper(1, [@g3, @g4], 2, 1, 10, 0, 'group_id')
      expect(res.length).to eq(8)
    end

    it 'should work with algorithm_id' do
      res = get_email_scores_from_helper(1, [@g3, @g4], 2, 1, 10, 0, 'algorithm_id')
      expect(res.length).to eq(8)
    end

    it 'should work with office_id' do
      res = get_email_scores_from_helper(1, [@g3, @g4], 2, 1, 10, 0, 'office_id')
      expect(res.length).to eq(8)
    end
  end

  describe 'get_email_stats_from_helper' do
    before do
      generate_data_for_acme
      FactoryGirl.create(:algorithm, id: 707, name: 'email traffic', algorithm_type_id: 1, algorithm_flow_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 1, score: 1, employee_id: @emp1, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 1, score: 2, employee_id: @emp2, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 1, score: 3, employee_id: @emp3, group_id: @g1, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 1, score: 4, employee_id: @emp4, group_id: @g2, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 1, score: 5, employee_id: @emp5, group_id: @g2, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 2, score: 2, employee_id: @emp1, group_id: @g3, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 2, score: 3, employee_id: @emp2, group_id: @g3, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 2, score: 4, employee_id: @emp3, group_id: @g3, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 2, score: 5, employee_id: @emp4, group_id: @g4, company_metric_id: 7, company_id: 1)
      CdsMetricScore.create!(algorithm_id: 707, snapshot_id: 2, score: 6, employee_id: @emp5, group_id: @g4, company_metric_id: 7, company_id: 1)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'should return result with timeSpent and a diff' do
      ret = get_email_stats_from_helper([], 2)
      expect(ret[:sum]).to eq(1.0)
      expect(ret[:avg]).to eq(0.2)
      expect(ret[:diff]).to eq(33.0)
    end

    it 'should retun timeSpentDiff of 0 if there is only one snapshot' do
      Snapshot.find(1).delete
      CdsMetricScore.where(snapshot_id: 1).delete_all
      ret = get_email_stats_from_helper([], 2)
      expect(ret[:sum]).to eq(1.0)
      expect(ret[:avg]).to eq(0.2)
      expect(ret[:diff]).to eq(0.0)
    end
  end
end

def generate_data_for_acme
  Company.create(id: 1, name: 'Acme')
  FactoryGirl.create(:snapshot, id: 1, snapshot_type: nil, timestamp: '2017-10-01')
  FactoryGirl.create(:snapshot, id: 2, snapshot_type: nil, timestamp: '2017-10-08')
  AlgorithmType.create(id: 1, name: 'measure')
  FactoryGirl.create(:metric, name: 'Happy', metric_type: 'measure', index: 1)
  FactoryGirl.create(:metric, name: 'Funny', metric_type: 'measure', index: 4)
  FactoryGirl.create(:algorithm, id: 701, name: 'happy', algorithm_type_id: 1, algorithm_flow_id: 1)
  FactoryGirl.create(:algorithm, id: 702, name: 'funny', algorithm_type_id: 1, algorithm_flow_id: 1)
  CompanyWithMetricsFactory.create_network_names
  FactoryGirl.create(:metric_name, id: 1, name: 'Happy', company_id: 1)
  FactoryGirl.create(:metric_name, id: 2, name: 'Funny', company_id: 1)

  FactoryGirl.create(:company_metric, id: 7, metric_id: 1, network_id: 3, company_id: 1, algorithm_id: 701, algorithm_type_id: 1)
  FactoryGirl.create(:company_metric, id: 8, metric_id: 2, network_id: 3, company_id: 1, algorithm_id: 702, algorithm_type_id: 1)

  @g1 = FactoryGirl.create(:group, name: 'group_1', snapshot_id: 1, external_id: 'group_1', company_id: 1).id
  @g2 = FactoryGirl.create(:group, name: 'group_2', snapshot_id: 1, external_id: 'group_2', company_id: 1, parent_group_id: @g1).id
  @g3 = FactoryGirl.create(:group, name: 'group_1', snapshot_id: 2, external_id: 'group_1', company_id: 1).id
  @g4 = FactoryGirl.create(:group, name: 'group_2', snapshot_id: 2, external_id: 'group_2', company_id: 1, parent_group_id: @g3).id

  @of1 = Office.create!(company_id: 1, name: 'Mishmeret').id
  @of2 = Office.create!(company_id: 1, name: 'Drorim').id

  @emp1 = FactoryGirl.create(:employee, email: 'email1@mail.com', group_id: @g1, company_id: 1, office_id: @of1).id
  @emp2 = FactoryGirl.create(:employee, email: 'email2@mail.com', group_id: @g1, company_id: 1, office_id: @of2).id
  @emp3 = FactoryGirl.create(:employee, email: 'email3@mail.com', group_id: @g1, company_id: 1, office_id: @of1).id
  @emp4 = FactoryGirl.create(:employee, email: 'email4@mail.com', group_id: @g2, company_id: 1, office_id: @of2).id
  @emp5 = FactoryGirl.create(:employee, email: 'email5@mail.com', group_id: @g2, company_id: 1, office_id: @of1).id

  ## At long last we can fill cds_metric_scores
  ## Groups data
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 1, employee_id: @emp1, group_id: @g1, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 2, employee_id: @emp2, group_id: @g1, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 3, employee_id: @emp3, group_id: @g1, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 4, employee_id: @emp4, group_id: @g2, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 5, employee_id: @emp5, group_id: @g2, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 2, employee_id: @emp1, group_id: @g3, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 3, employee_id: @emp2, group_id: @g3, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 4, employee_id: @emp3, group_id: @g3, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 5, employee_id: @emp4, group_id: @g4, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 6, employee_id: @emp5, group_id: @g4, company_metric_id: 7, company_id: 1)

  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 1, score: 3, employee_id: @emp1, group_id: @g1, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 1, score: 2, employee_id: @emp2, group_id: @g1, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 1, score: 3, employee_id: @emp3, group_id: @g1, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 1, score: 4, employee_id: @emp4, group_id: @g2, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 1, score: 5, employee_id: @emp5, group_id: @g2, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 2, score: 3, employee_id: @emp1, group_id: @g3, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 2, score: 3, employee_id: @emp2, group_id: @g3, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 2, score: 4, employee_id: @emp3, group_id: @g3, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 2, score: 5, employee_id: @emp4, group_id: @g4, company_metric_id: 8, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 702, snapshot_id: 2, score: 6, employee_id: @emp5, group_id: @g4, company_metric_id: 8, company_id: 1)
end
