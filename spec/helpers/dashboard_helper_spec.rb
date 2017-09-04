require 'spec_helper'

describe DashboardHelper, type: :helper do
  before do
    NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)

    @company = FactoryGirl.create(:company)
    FactoryGirl.create(:snapshot, id: 1, company_id: 1, snapshot_type: nil)
    @parent_group = FactoryGirl.create(:group, name: 'parent_group', company_id: 1)
    @g1 = FactoryGirl.create(:group, name: 'group_1', company_id: 1, parent_group_id:  @parent_group.id)
    @g2 = FactoryGirl.create(:group, name: 'group_2', company_id: 1, parent_group_id:  @parent_group.id)
    @g3 = FactoryGirl.create(:group, name: 'group_3', company_id: 1, parent_group_id:  @parent_group.id)
    @g4 = FactoryGirl.create(:group, name: 'group_4_1', company_id: 1, parent_group_id:  @g1.id)
    @emp_1 = FactoryGirl.create(:employee, company_id: 1, group_id: @g1.id)
    @emp_2 = FactoryGirl.create(:employee, company_id: 1, group_id: @g1.id)
    @emp_3 = FactoryGirl.create(:employee, company_id: 1, group_id: @g2.id)
    @emp_4 = FactoryGirl.create(:employee, company_id: 1, group_id: @g3.id)
    @emp_5 = FactoryGirl.create(:employee, company_id: 1, group_id: @g4.id)
    @network_nodes_1 = {employee_from_id: @emp_1.id, employee_to_id: @emp_3.id, snapshot_id: 1, company_id: @company.id}
    (1..18).each do |i|
      @network_nodes_1['n' + i.to_s] = i
    end
    NetworkSnapshotData.create_email_adapter(@network_nodes_1)
    # @network_nodes_1.save!
    @network_nodes_2 = {employee_from_id: @emp_3.id, employee_to_id: @emp_1.id, snapshot_id: 1, company_id: @company.id}
    (1..18).each do |i|
      @network_nodes_2['n' + i.to_s] = i + 2
    end
    NetworkSnapshotData.create_email_adapter(@network_nodes_2)
    # @network_nodes_2.save!

    @network_nodes_3 = {employee_from_id: @emp_1.id, employee_to_id: @emp_4.id, snapshot_id: 1, company_id: @company.id}
    (1..18).each do |i|
      @network_nodes_3['n' + i.to_s] = i + 1
    end
    NetworkSnapshotData.create_email_adapter(@network_nodes_3)
    # @network_nodes_3.save!
    NetworkSnapshotData.create_email_adapter(employee_from_id: @emp_4.id, employee_to_id: @emp_5.id, snapshot_id: 1, n1: 10, n2: 50, significant_level: :not_significant, company_id: @company.id)
    NetworkSnapshotData.create_email_adapter(employee_from_id: @emp_4.id, employee_to_id: @emp_2.id, snapshot_id: 1, n1: 10, n2: 0, significant_level: :meaningfull, company_id: @company.id)
    NetworkSnapshotData.create_email_adapter(employee_from_id: @emp_1.id, employee_to_id: @emp_4.id, snapshot_id: 1, n1: 10, n2: 10, significant_level: :meaningfull, company_id: @company.id)
    NetworkSnapshotData.create_email_adapter(employee_from_id: @emp_3.id, employee_to_id: @emp_4.id, snapshot_id: 1, n1: 35, n2: 50, significant_level: :meaningfull, company_id: @company.id)

    @snapshot_list = NetworkSnapshotData.all
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe ', get_all_level_1_groups_with_employess' do
    it ', should return array of groups and emps in sub groups' do
      groups_arr = DashboardHelper.get_all_level_1_groups_with_employess(@parent_group.id)
      expect(groups_arr[0][:empsarr].sort).to eq([@emp_1.id, @emp_2.id, @emp_5.id])
      expect(groups_arr[1][:empsarr]).to eq([@emp_3.id])
      expect(groups_arr[2][:empsarr]).to eq([@emp_4.id])
    end
  end

  describe 'build_tree_map' do
    before do
      Algorithm.find_or_create_by!(id: 401, name: 'l2_internal_collaboration', algorithm_type_id: AlgorithmType::HIGHER_LEVEL)
      Algorithm.find_or_create_by!(id: 402, name: 'l2_external_collaboration', algorithm_type_id: AlgorithmType::HIGHER_LEVEL)
      Algorithm.find_or_create_by!(id: 403, name: 'l2_time_utilization', algorithm_type_id: AlgorithmType::HIGHER_LEVEL)
      Algorithm.find_or_create_by!(id: 404, name: 'l2_workload_heterogeny', algorithm_type_id: AlgorithmType::HIGHER_LEVEL)
      Algorithm.find_or_create_by!(id: 405, name: 'l2_synergy', algorithm_type_id: AlgorithmType::HIGHER_LEVEL)
      Algorithm.find_or_create_by!(id: 406, name: 'l2_influencers', algorithm_type_id: AlgorithmType::HIGHER_LEVEL)
      @s = FactoryGirl.create(:snapshot, id: 2, company_id: 1, snapshot_type: nil)
      @g1 = FactoryGirl.create(:group, name: 'group_1', company_id: 1, parent_group_id: nil)
      @g2 = FactoryGirl.create(:group, name: 'group_2', company_id: 1, parent_group_id: @g1.id)
      @g3 = FactoryGirl.create(:group, name: 'group_3', company_id: 1, parent_group_id: @g1.id)
      @g4 = FactoryGirl.create(:group, name: 'group_4', company_id: 1, parent_group_id: @g1.id)

      (0..5).each{ FactoryGirl.create(:employee, group_id: @g1.id) }
      (0..5).each{ FactoryGirl.create(:employee, group_id: @g2.id) }
      (0..5).each{ FactoryGirl.create(:employee, group_id: @g3.id) }
      (0..5).each{ FactoryGirl.create(:employee, group_id: @g4.id) }

      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 402, group_id: @g4.id, score: 5, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 402, group_id: @g4.id, score: 5, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 402, group_id: @g4.id, score: 6, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 402, group_id: @g4.id, score: 6, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 1, employee_id: -1, algorithm_id: 401, group_id: @g2.id, score: 7, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 2, employee_id: -1, algorithm_id: 403, group_id: @g2.id, score: 7, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 3, employee_id: -1, algorithm_id: 404, group_id: @g3.id, score: 8, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 4, employee_id: -1, algorithm_id: 405, group_id: @g3.id, score: 8, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 406, group_id: @g4.id, score: 9, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 404, group_id: @g4.id, score: 9, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 405, group_id: @g4.id, score: 9, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 406, group_id: @g4.id, score: 9, snapshot_id: @s.id)
      CdsMetricScore.create!(company_id: 1, company_metric_id: 6, employee_id: -1, algorithm_id: 403, group_id: @g4.id, score: 9, snapshot_id: @s.id)

      @uic7 = UiLevelConfiguration.create!(company_id: 1, company_metric_id: 99, level: 6, display_order: 1)
      @uic8 = UiLevelConfiguration.create!(company_id: 1, company_metric_id: 79, level: 6, display_order: 2)
      @uic9 = UiLevelConfiguration.create!(company_id: 1, company_metric_id: 69, level: 6, display_order: 3)
      @uic10 = UiLevelConfiguration.create!(company_id: 1, company_metric_id: 69, level: 6, display_order: 5)
      @uic11 = UiLevelConfiguration.create!(company_id: 1, company_metric_id: 69, level: 8, display_order: 1)
      @uic12 = UiLevelConfiguration.create!(company_id: 1, company_metric_id: 69, level: 7, display_order: 2)

      @uic1 = UiLevelConfiguration.create!(company_id: 1, parent_id: @uic7.id, company_metric_id: 1, level: 1, display_order: 1)
      @uic2 = UiLevelConfiguration.create!(company_id: 1, parent_id: @uic8.id, company_metric_id: 2, level: 2, display_order: 2)
      @uic3 = UiLevelConfiguration.create!(company_id: 1, parent_id: @uic9.id, company_metric_id: 3, level: 3, display_order: 3)
      @uic4 = UiLevelConfiguration.create!(company_id: 1, parent_id: @uic10.id, company_metric_id: 4, level: 4, display_order: 4)
      @uic5 = UiLevelConfiguration.create!(company_id: 1, parent_id: @uic11.id, company_metric_id: 5, level: 5, display_order: 5)
      @uic6 = UiLevelConfiguration.create!(company_id: 1, parent_id: @uic12.id, company_metric_id: 6, level: 6, display_order: 6)

      @res = DashboardHelper.build_tree_map(@g1.id)
    end
    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should return treemap hirarchy with 10 algorithms scores' do
      expect(@res[:treemap].count).to eq 2
      expect(@res[:treemap][:good_scores].count).to eq 5
      expect(@res[:treemap][:bad_scores].count).to eq 5
    end

    it 'should order the treemap from high to low and from plus to minus' do
      res = DashboardHelper.build_tree_map(@g1.id)
      good_arr = res[:treemap][:good_scores]
      good_scores = good_arr.map { |e| e[:score] }
      sorted_good = good_scores.sort { |x,y| y<=>x }
      bad_arr  = res[:treemap][:bad_scores]
      bad_scores  = bad_arr.map { |e| e[:score] }
      sorted_bad = bad_scores.sort

      expect(good_scores).to eq(sorted_good)
      expect(bad_scores ).to eq(sorted_bad)
    end
    it 'should add to the results the correct ui level configuration' do
      expect(@res[:treemap][:good_scores][0][:level]).to eq 6
      expect(@res[:treemap][:good_scores][0][:display_order]).to eq 6
    end
  end
end
