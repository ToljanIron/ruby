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
  describe 'Optimize cds_get_measure_data' do
    before do
      Company.create(id: 1, name: 'Acme')
      FactoryBot.create(:snapshot, id: 1, snapshot_type: nil)
      FactoryBot.create(:snapshot, id: 2, snapshot_type: nil)
      AlgorithmType.create(id: 1, name: 'measure')
      FactoryBot.create(:metric, name: 'Happy', metric_type: 'measure', index: 1)
      FactoryBot.create(:metric, name: 'Funny', metric_type: 'measure', index: 4)
      FactoryBot.create(:algorithm, id: 28, name: 'happy', algorithm_type_id: 1, algorithm_flow_id: 1)
      FactoryBot.create(:algorithm, id: 29, name: 'funny', algorithm_type_id: 1, algorithm_flow_id: 1)
      CompanyWithMetricsFactory.create_network_names
      FactoryBot.create(:metric_name, id: 1, name: 'Happy', company_id: 1)
      FactoryBot.create(:metric_name, id: 2, name: 'Funny', company_id: 1)

      FactoryBot.create(:company_metric, id: 7, metric_id: 1, network_id: 3, company_id: 1, algorithm_id: 28, algorithm_type_id: 1)
      FactoryBot.create(:company_metric, id: 8, metric_id: 2, network_id: 3, company_id: 1, algorithm_id: 29, algorithm_type_id: 1)

      @g1 = FactoryBot.create(:group, name: 'group_1', company_id: 1).id
      @g2 = FactoryBot.create(:group, name: 'group_1', company_id: 1, parent_group_id: @g1).id

      @emp1 = FactoryBot.create(:employee, email: 'email1@mail.com', group_id: @g1, company_id: 1).id
      @emp2 = FactoryBot.create(:employee, email: 'email2@mail.com', group_id: @g1, company_id: 1).id
      @emp3 = FactoryBot.create(:employee, email: 'email3@mail.com', group_id: @g1, company_id: 1).id
      @emp4 = FactoryBot.create(:employee, email: 'email4@mail.com', group_id: @g2, company_id: 1).id
      @emp5 = FactoryBot.create(:employee, email: 'email5@mail.com', group_id: @g2, company_id: 1).id

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
      FactoryBot.reload
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
      FactoryBot.reload
    end

    describe 'calculate_group_top_scores' do
      xit 'calculate_top_scores should return a list of groups when given group_id' do
        res = calculate_group_top_scores(1, 2, [@g3, @g4], [701, 702])
        expect(res.length).to eq(2)
      end

      xit 'calculate_top_scores should return a list of groups when given algorithm_id' do
        res = calculate_group_top_scores(1, 2, [@g3, @g4], [701, 702])
        expect(res.length).to eq(2)
        expect(res[0]).to eq(4)
      end
    end

    xit 'should work with group_id' do
      res = get_email_scores_from_helper(1, [@g3, @g4], 2, 1, 10, 0, 'group_id')
      expect(res.length).to eq(8)
    end

    xit 'should work with algorithm_id' do
      res = get_email_scores_from_helper(1, [@g3, @g4], 2, 1, 10, 0, 'algorithm_id')
      expect(res.length).to eq(8)
    end

    xit 'should work with office_id' do
      res = get_email_scores_from_helper(1, [@g3, @g4], 2, 1, 10, 0, 'office_id')
      expect(res.length).to eq(8)
    end
  end

  describe 'get_email_stats_from_helper' do
    before do
      generate_data_for_acme
      FactoryBot.create(:algorithm, id: 707, name: 'email traffic', algorithm_type_id: 1, algorithm_flow_id: 1)
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
      FactoryBot.reload
    end

    xit 'should return result with timeSpent and a diff' do
      ret = get_email_stats_from_helper([], 2, 1, 'By Month')
      expect(ret[:sum]).to eq(1.0)
      expect(ret[:avg]).to eq(0.2)
      expect(ret[:diff]).to eq(33.0)
    end

    xit 'should retun timeSpentDiff of 0 if there is only one snapshot' do
      Snapshot.find(1).delete
      CdsMetricScore.where(snapshot_id: 1).delete_all
      ret = get_email_stats_from_helper([], 2, 1, 'By Month')
      pp ret
      expect(ret[:sum]).to eq(1.0)
      expect(ret[:avg]).to eq(0.2)
      expect(ret[:diff]).to eq(0.0)
    end
  end

end

describe 'cds_aggregation_query' do
  before :all do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
    generate_data_for_acme
    Group.prepare_groups_for_hierarchy_queries(1)
    Group.prepare_groups_for_hierarchy_queries(2)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
  end

  it 'should work' do
    cid = 1
    interval = 'Oct/17'
    group_wherepart = "outg.external_id in ('group_1', 'group_2')"
    aids = [701]
    extids = ['group_1', 'group_2']

    res = cds_aggregation_query(
      cid,
      interval,
      group_wherepart,
      '1 = 1',
      '1 = 1',
      aids,
      'month',
      extids
    )

    expect(res.length).to eq(2)
  end
end

########################################################################
# These tests are performed on an abstract algorithm, but a good
#   way to think about is as if it measures average number of
#   partricipants in meetings. The numberator is number of participants
#   and the denominator is the number of meetings
########################################################################
describe 'gauge aggregations' do

  ######################################################################
  # Create this group hierarchy:
  #               g0
  #              /  \
  #             g1   g2
  #                 /  \
  #                g3  g4
  #######################################
  before :all do
    generate_hierarchy_with_gauge_algo
    Group.prepare_groups_for_hierarchy_queries(1)
  end

  after :each do
    CdsMetricScore.delete_all
  end

  describe 'total_sum_from_gauge' do
    it 'sanity should pass' do
      CdsMetricScore.create!(numerator: 11.0, denominator: 1.0, group_id: @g0, company_metric_id: 7, company_id: 1, snapshot_id: 1, algorithm_id: 701, employee_id: -1, score: 1.0)
      CdsMetricScore.create!(numerator: 19.0, denominator: 7.0, group_id: @g1, company_metric_id: 7, company_id: 1, snapshot_id: 1, algorithm_id: 701, employee_id: -1, score: 1.0)
      CdsMetricScore.create!(numerator: 10.0, denominator: 1.0, group_id: @g2, company_metric_id: 7, company_id: 1, snapshot_id: 1, algorithm_id: 701, employee_id: -1, score: 1.0)
      CdsMetricScore.create!(numerator: 13.0, denominator: 5.0, group_id: @g3, company_metric_id: 7, company_id: 1, snapshot_id: 1, algorithm_id: 701, employee_id: -1, score: 1.0)
      CdsMetricScore.create!(numerator: 10.0, denominator: 4.0, group_id: @g4, company_metric_id: 7, company_id: 1, snapshot_id: 1, algorithm_id: 701, employee_id: -1, score: 1.0)
      extids = ['g0', 'g1', 'g2', 'g3', 'g4']
      res = total_sum_from_gauge(1, 'Oct/17', 'month', extids, 701)
      expect(res).to eq(63.0)
    end
  end
end


def generate_data_for_acme
  Company.create(id: 1, name: 'Acme')
  FactoryBot.create(:snapshot, id: 1, snapshot_type: nil, timestamp: '2017-10-01')
  FactoryBot.create(:snapshot, id: 2, snapshot_type: nil, timestamp: '2017-10-08')
  AlgorithmType.create(id: 1, name: 'measure')
  FactoryBot.create(:metric, name: 'Happy', metric_type: 'measure', index: 1)
  FactoryBot.create(:metric, name: 'Funny', metric_type: 'measure', index: 4)
  FactoryBot.create(:algorithm, id: 701, name: 'happy', algorithm_type_id: 1, algorithm_flow_id: 1)
  FactoryBot.create(:algorithm, id: 702, name: 'funny', algorithm_type_id: 1, algorithm_flow_id: 1)
  CompanyWithMetricsFactory.create_network_names
  FactoryBot.create(:metric_name, id: 1, name: 'Happy', company_id: 1)
  FactoryBot.create(:metric_name, id: 2, name: 'Funny', company_id: 1)

  FactoryBot.create(:company_metric, id: 7, metric_id: 1, network_id: 3, company_id: 1, algorithm_id: 701, algorithm_type_id: 1)
  FactoryBot.create(:company_metric, id: 8, metric_id: 2, network_id: 3, company_id: 1, algorithm_id: 702, algorithm_type_id: 1)

  @g1 = FactoryBot.create(:group, name: 'group_1', snapshot_id: 1, external_id: 'group_1', company_id: 1).id
  @g2 = FactoryBot.create(:group, name: 'group_2', snapshot_id: 1, external_id: 'group_2', company_id: 1, parent_group_id: @g1).id
  @g3 = FactoryBot.create(:group, name: 'group_1', snapshot_id: 2, external_id: 'group_1', company_id: 1).id
  @g4 = FactoryBot.create(:group, name: 'group_2', snapshot_id: 2, external_id: 'group_2', company_id: 1, parent_group_id: @g3).id

  @of1 = Office.create!(company_id: 1, name: 'Mishmeret').id
  @of2 = Office.create!(company_id: 1, name: 'Drorim').id

  @emp1 = FactoryBot.create(:employee, email: 'email1@mail.com', group_id: @g1, company_id: 1, office_id: @of1, snapshot_id: 1).id
  @emp2 = FactoryBot.create(:employee, email: 'email2@mail.com', group_id: @g1, company_id: 1, office_id: @of1, snapshot_id: 1).id
  @emp3 = FactoryBot.create(:employee, email: 'email3@mail.com', group_id: @g1, company_id: 1, office_id: @of1, snapshot_id: 1).id
  @emp4 = FactoryBot.create(:employee, email: 'email4@mail.com', group_id: @g2, company_id: 1, office_id: @of1, snapshot_id: 1).id
  @emp5 = FactoryBot.create(:employee, email: 'email5@mail.com', group_id: @g2, company_id: 1, office_id: @of1, snapshot_id: 1).id

  @emp6 = FactoryBot.create(:employee, email: 'email6@mail.com', group_id: @g3, company_id: 1, office_id: @of1, snapshot_id: 2).id
  @emp7 = FactoryBot.create(:employee, email: 'email7@mail.com', group_id: @g3, company_id: 1, office_id: @of1, snapshot_id: 2).id
  @emp8 = FactoryBot.create(:employee, email: 'email8@mail.com', group_id: @g3, company_id: 1, office_id: @of1, snapshot_id: 2).id
  @emp9 = FactoryBot.create(:employee, email: 'email9@mail.com', group_id: @g4, company_id: 1, office_id: @of1, snapshot_id: 2).id
  @emp0 = FactoryBot.create(:employee, email: 'email0@mail.com', group_id: @g4, company_id: 1, office_id: @of1, snapshot_id: 2).id

  ## At long last we can fill cds_metric_scores
  ## Groups data
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 1, employee_id: @emp1, group_id: @g1, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 2, employee_id: @emp2, group_id: @g1, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 3, employee_id: @emp3, group_id: @g1, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 4, employee_id: @emp4, group_id: @g2, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 1, score: 5, employee_id: @emp5, group_id: @g2, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 2, employee_id: @emp6, group_id: @g3, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 3, employee_id: @emp7, group_id: @g3, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 4, employee_id: @emp8, group_id: @g3, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 5, employee_id: @emp9, group_id: @g4, company_metric_id: 7, company_id: 1)
  CdsMetricScore.create!(algorithm_id: 701, snapshot_id: 2, score: 6, employee_id: @emp0, group_id: @g4, company_metric_id: 7, company_id: 1)

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

def generate_hierarchy_with_gauge_algo
  Company.create(id: 1, name: 'Acme')
  FactoryBot.create(:snapshot, id: 1, snapshot_type: nil, timestamp: '2017-10-01')
  AlgorithmType.create(id: 5, name: 'measure')
  FactoryBot.create(:metric, name: 'Happy', metric_type: 'measure', index: 1)
  FactoryBot.create(:algorithm, id: 701, name: 'happy', algorithm_type_id: 1, algorithm_flow_id: 1)
  CompanyWithMetricsFactory.create_network_names
  FactoryBot.create(:metric_name, id: 1, name: 'Happy', company_id: 1)
  FactoryBot.create(:company_metric, id: 7, metric_id: 1, network_id: 3, company_id: 1, algorithm_id: 701, algorithm_type_id: 1)

  @g0 = FactoryBot.create(:group, name: 'g0', external_id: 'g0').id
  @g1 = FactoryBot.create(:group, name: 'g1', external_id: 'g1', parent_group_id: @g0).id
  @g2 = FactoryBot.create(:group, name: 'g2', external_id: 'g2', parent_group_id: @g0).id
  @g3 = FactoryBot.create(:group, name: 'g3', external_id: 'g3', parent_group_id: @g2).id
  @g4 = FactoryBot.create(:group, name: 'g4', external_id: 'g4', parent_group_id: @g2).id

end
