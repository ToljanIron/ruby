require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/create_alerts_task_helper.rb'

describe CreateAlertsTaskHelper, type:  :helper do
  before do
    FactoryGirl.create(:company)
    FactoryGirl.create(:snapshot)
    FactoryGirl.create(:algorithm, id: 103,  name: 'calc_gauges', algorithm_type_id: 5)
    FactoryGirl.create(:metric_name, id: 3, name: 'Gauges')
    FactoryGirl.create(:company_metric, id: 3, metric_id: 3, network_id: 3, algorithm_id: 103, algorithm_type_id: 5)
    FactoryGirl.create(:algorithm, id: 104,  name: 'calc_measures', algorithm_type_id: 1)
    FactoryGirl.create(:metric_name, id: 4, name: 'Measures')
    FactoryGirl.create(:company_metric, id: 4, metric_id: 4, network_id: 4, algorithm_id: 104, algorithm_type_id: 1)
    (0..15).each do |gid|
      size = 2 if (gid % 5) == 0
      size = 4 if (gid % 5) != 0
      FactoryGirl.create(:group, id: gid, hierarchy_size: size)
    end

    ## set min group size to 2
    allow_any_instance_of(CreateAlertsTaskHelper).to receive(:min_group_size).and_return( 2 )
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'create_alert' do
    before do

      Group.find(1).update(hierarchy_size: 7, nsleft: 1, nsright: 10)
      Group.find(2).update(parent_group_id: 1, hierarchy_size: 2, nsleft: 2, nsright: 3)
      Group.find(3).update(parent_group_id: 1, hierarchy_size: 5, nsleft: 4, nsright: 9)
      Group.find(4).update(parent_group_id: 3, hierarchy_size: 3, nsleft: 5, nsright: 6)
      Group.find(5).update(parent_group_id: 3, hierarchy_size: 1, nsleft: 7, nsright: 8)

      FactoryGirl.create(:employee, id: 1, group_id: 2)
      FactoryGirl.create(:employee, id: 2, group_id: 2)
      FactoryGirl.create(:employee, id: 3, group_id: 3)
      FactoryGirl.create(:employee, id: 4, group_id: 4)
      FactoryGirl.create(:employee, id: 5, group_id: 4)
      FactoryGirl.create(:employee, id: 6, group_id: 4)
      FactoryGirl.create(:employee, id: 7, group_id: 5)
      FactoryGirl.create(:cds_metric_score, group_id: 1, employee_id: 1,  z_score: 2.1,  algorithm_id: 104, company_metric_id: 4)
      FactoryGirl.create(:cds_metric_score, group_id: 1, employee_id: 2,  z_score: 1.1,  algorithm_id: 104, company_metric_id: 4)
      FactoryGirl.create(:cds_metric_score, group_id: 1, employee_id: 3,  z_score: 3.3,  algorithm_id: 104, company_metric_id: 4)
      FactoryGirl.create(:cds_metric_score, group_id: 1, employee_id: 4,  z_score: 2.1,  algorithm_id: 104, company_metric_id: 4)
      FactoryGirl.create(:cds_metric_score, group_id: 1, employee_id: 5,  z_score: 2.1,  algorithm_id: 104, company_metric_id: 4)
      FactoryGirl.create(:cds_metric_score, group_id: 1, employee_id: 6,  z_score: 0.1,  algorithm_id: 104, company_metric_id: 4)
      FactoryGirl.create(:cds_metric_score, group_id: 1, employee_id: 7,  z_score: 2.1,  algorithm_id: 104, company_metric_id: 4)
    end

    it 'should return highest result' do
      res = create_alerts_for_extreme_z_score_measures(1, 1, 104)
      expect(res.length).to eq(1)
      expect(res[0].group_id).to eq(3)
      expect(res[0].alert_type).to eq(2)
    end

    describe 'extreme_z_score_measure_query' do
      it 'should create one high value alert for the first group' do
        res = extreme_z_score_measure_query(1, 1, [1, 2, 3, 4], 104, CreateAlertsTaskHelper::DIR_HIGH)
        expect(res).to eq(3)
      end
    end
  end

  describe 'create_alerts_for_extreme_z_score_gauges' do
    before do
      FactoryGirl.create(:cds_metric_score, group_id: 1,  z_score: 2.1,  algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 2,  z_score: 1.3,  algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 3,  z_score: 1.1,  algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 4,  z_score: 0.9,  algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 5,  z_score: 0.4,  algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 6,  z_score: 0.2,  algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 7,  z_score: 0.2,  algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 8,  z_score: 0.1,  algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 9,  z_score: -0.5, algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 10, z_score: -0.6, algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 11, z_score: -0.8, algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 12, z_score: -1.1, algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 13, z_score: -1.1, algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 14, z_score: -1.4, algorithm_id: 103, company_metric_id: 3)
      FactoryGirl.create(:cds_metric_score, group_id: 15, z_score: -1.4, algorithm_id: 103, company_metric_id: 3)
    end

    it 'should create one high value alert for the first group' do
      als = create_alerts_for_extreme_z_score_gauges(1, 1, 103)
      expect(als.length).to eq(1)
      expect(als[0].group_id).to eq(1)
      expect(als[0].direction).to eq('high')
    end

    it 'should create one low value alert' do
      CdsMetricScore.where(group_id:  1).last.update!(z_score: 1.0)
      CdsMetricScore.where(group_id: 13).last.update!(z_score: -3.0)
      CdsMetricScore.where(group_id: 14).last.update!(z_score: -3.0)
      CdsMetricScore.where(group_id: 15).last.update!(z_score: -3.0)
      als = create_alerts_for_extreme_z_score_gauges(1, 1, 103)
      expect(als.length).to eq(1)
      expect(als[0].direction).to eq('low')
    end

    it 'should create no alerts becuase group with extreme score is too small' do
      CdsMetricScore.where(group_id:  1).last.update!(z_score: 1.0)
      CdsMetricScore.where(group_id: 15).last.update!(z_score: -3.0)
      als = create_alerts_for_extreme_z_score_gauges(1, 1, 103)
      expect(als.length).to eq(0)
    end

    it 'should create no alerts' do
      CdsMetricScore.where(group_id:  1).last.update!(z_score: 1.0)
      als = create_alerts_for_extreme_z_score_gauges(1, 1, 103)
      expect(als.length).to eq(0)
    end

    it 'should create two alerts' do
      CdsMetricScore.where(group_id: 13).last.update!(z_score: -3.0)
      als = create_alerts_for_extreme_z_score_gauges(1, 1, 103)
      expect(als.length).to eq(2)
    end
  end
end
