require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/precalculate_metric_scores_for_custom_data_system_helper.rb'
require './spec/factories/company_with_metrics_factory.rb'
require 'date'

include CompanyWithMetricsFactory

describe PrecalculateMetricScoresForCustomDataSystemHelper, type: :helper do
  let(:group1) { FactoryGirl.create(:group, id: 1, company_id: 1, name: 'group1') }
  let(:group2) { FactoryGirl.create(:group, id: 2, company_id: 1, name: 'group2') }
  let(:employee1) { FactoryGirl.create(:group_employee, id: 1, company_id: 1, group_id: 1) }
  let(:employee3) { FactoryGirl.create(:group_employee, id: 3, company_id: 1, group_id: 2) }
  let(:employee2) { FactoryGirl.create(:employee, id: 2, company_id: 2, email: 'emp2@e.com', external_id: 2) }


  before do
    DatabaseCleaner.clean_with(:truncation)

    Company.create(id: 1, name: 'company1')
    Snapshot.create(id: 1, company_id: 1, name: 'first')
    create_network_names
    group1
    employee1
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'cds_calculate_z_scores' do
    before do
      AlgorithmType.create(id: 1, name: 'measure')
      FactoryGirl.create(:algorithm, id: 101,  name: 'algo-101', algorithm_type_id: 1)
      FactoryGirl.create(:algorithm, id: 102,  name: 'algo-102', algorithm_type_id: 1)
      FactoryGirl.create(:algorithm, id: 103,  name: 'algo-103', algorithm_type_id: 1)
      (1..5).each do |i|
        (1..3).each do |j|
          CdsMetricScore.create!(group_id: i, algorithm_id: (100 + j), score: i, company_id: 1, snapshot_id: 1, company_metric_id: 1, employee_id: -1)
        end
      end
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'should calculate correct z_scores' do
      cds_calculate_z_scores_for_measures(1,1)
      scores = CdsMetricScore.where(algorithm_id: 101).pluck(:z_score)
      expect( scores.first ).not_to be_nil
      expect( scores[2] ).to be(0.0)
      expect( scores.first ).to be( scores.last * (-1) )
    end
  end

  describe 'cds_calculate_z_scores' do
    before do
      AlgorithmType.create(id: 5, name: 'gauge')
      FactoryGirl.create(:algorithm, id: 101,  name: 'algo-101', algorithm_type_id: 5)
      FactoryGirl.create(:algorithm, id: 102,  name: 'algo-102', algorithm_type_id: 5)
      FactoryGirl.create(:algorithm, id: 103,  name: 'algo-103', algorithm_type_id: 5)
      (1..5).each do |i|
        (1..3).each do |j|
          CdsMetricScore.create!(group_id: i, algorithm_id: (100 + j), score: i, company_id: 1, snapshot_id: 1, company_metric_id: 1, employee_id: -1)
        end
      end
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'should calculate correct z_scores' do
      cds_calculate_z_scores_for_gauges(1,1)
      scores = CdsMetricScore.where(algorithm_id: 101)
      expect( scores.first.z_score ).not_to be_nil
      expect( scores[2].z_score ).to be(0.0)
      expect( scores.first.z_score ).to eq( scores.last.z_score )
    end

    it 'should rewrite if rewrite=true' do
      CdsMetricScore.last.update(z_score: 1000.0)
      cds_calculate_z_scores_for_gauges(1, 1, true)
      expect( CdsMetricScore.last.z_score ).not_to be(1000.0)
    end

    it 'should not rewrite if rewrite=false' do
      CdsMetricScore.last.update(z_score: 1000.0)
      cds_calculate_z_scores_for_gauges(1, 1)
      expect( CdsMetricScore.last.z_score ).to be(1000.0)
    end
  end

  describe 'recalculate_score_for_central_and_negative_algorithms' do
    it 'should leave score same if both directions are the same' do
      new_score = recalculate_score_for_central_and_negative_algorithms(0.5, Algorithm::SCORE_SKEW_HIGH_IS_GOOD, Algorithm::SCORE_SKEW_HIGH_IS_GOOD)
      expect(new_score).to be(0.5)
    end

    it 'should flip score if one direction is high is good and the other is opposite ' do
      new_score = recalculate_score_for_central_and_negative_algorithms(0.5, Algorithm::SCORE_SKEW_HIGH_IS_GOOD, Algorithm::SCORE_SKEW_HIGH_IS_BAD)
      expect(new_score).to be(-0.5)
    end

    it 'when sone is central and parent is good should transform son so 0 becomes 1' do
      new_score = recalculate_score_for_central_and_negative_algorithms(0, Algorithm::SCORE_SKEW_HIGH_IS_GOOD, Algorithm::SCORE_SKEW_CENTRAL)
      expect(new_score).to be(1.0)
    end

    it 'when sone is central and parent is good should transform son so high scores become close to -1' do
      new_score = recalculate_score_for_central_and_negative_algorithms(2, Algorithm::SCORE_SKEW_HIGH_IS_GOOD, Algorithm::SCORE_SKEW_CENTRAL)
      expect(new_score).to be < -0.9
    end

    it 'when sone is central and parent is high is bad should transform son so low scores become close to -1' do
      new_score = recalculate_score_for_central_and_negative_algorithms(2, Algorithm::SCORE_SKEW_HIGH_IS_BAD, Algorithm::SCORE_SKEW_CENTRAL)
      expect(new_score).to be > 0.9
    end

    it 'when sone is central and parent is high is bad should transform son so 0 scores become close to 1' do
    end
  end
end

describe 'InterAct' do
  before() do
    DatabaseCleaner.clean_with(:truncation)
    Company.create!(id: 1, name: 'testcom', randomize_image: true, active: true)
    snapshot_factory_create(id: 45, name: '2015-06', snapshot_type: 3, company_id: 2)
    Questionnaire.create!(id: 1, company_id: 1, name: 'Test quest', snapshot_id: 45)
    QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: 1, question_id: 11, network_id: 1)
    QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: 1, question_id: 12, network_id: 2)
    Group.create!(id: 3, name: 'Testcom', company_id: 1, parent_group_id: nil, snapshot_id: 45)
    Group.create!(id: 4, name: 'QA',      company_id: 1, parent_group_id: 3, snapshot_id: 45)
    Employee.create!(id: 1, company_id: 1, email: 'pete1@sala.com', external_id: '11', first_name: 'Dave1', last_name: 'sala', group_id: 3)
    Employee.create!(id: 2, company_id: 1, email: 'pete2@sala.com', external_id: '12', first_name: 'Dave2', last_name: 'sala', group_id: 3)
    Employee.create!(id: 3, company_id: 1, email: 'pete3@sala.com', external_id: '13', first_name: 'Dave3', last_name: 'sala', group_id: 4)
    Employee.create!(id: 4, company_id: 1, email: 'pete4@sala.com', external_id: '14', first_name: 'Dave4', last_name: 'sala', group_id: 4)
    NetworkName.create!(id: 1, name: 'Advice', company_id: 1, questionnaire_id: 1)
    NetworkName.create!(id: 2, name: 'Stam',   company_id: 1, questionnaire_id: 1)

    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 1, to_employee_id: 3, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 3, to_employee_id: 2, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 3, to_employee_id: 4, value: 1)

    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 1, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 2, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 3, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 2, to_employee_id: 4, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 1, to_employee_id: 3, value: 1)
  end

  describe 'save_generic_socre' do
    it 'should save score to database' do
      save_generic_socre(1, 45, 1, 3, 1, 88, 601, 5)
      expect( CdsMetricScore.count ).to eq(1)
      save_generic_socre(1, 45, 1, 3, 1, 89, 602, 2)
      expect( CdsMetricScore.count ).to eq(2)
    end
  end

  describe 'cds_calculate_scores_for_generic_network' do
    it 'should go over all results and save to db' do
      allow(InteractAlgorithmsHelper).to receive(:calculate_network_indegree).and_return(
        [{'employee_id' => '1', 'score': '2'}, {'employee_id' => '2', 'score' => '3'}]
      )
      allow(InteractAlgorithmsHelper).to receive(:calculate_network_outdegree).and_return(
        [{'employee_id' => '1', 'score': '2'}, {'employee_id' => '5', 'score' => '6'}]
      )
      cds_calculate_scores_for_generic_network(1, 45, 1, 3, 100, 101)
      expect( CdsMetricScore.count ).to eq(4)
    end
  end

  describe 'generate_company_metrics_for_network_out' do
    it 'should created a new company_metric if does not exist' do
      generate_company_metrics_for_network_out(1, 1)
      expect(CompanyMetric.count).to eq(1)
    end

    it 'should created a new company_metric if does exist' do
      generate_company_metrics_for_network_out(1, 1)
      generate_company_metrics_for_network_out(1, 1)
      expect(CompanyMetric.count).to eq(1)
    end
  end

  describe 'generate_company_metrics_for_network_in' do
    it 'should created a new company_metric if does not exist' do
      generate_company_metrics_for_network_in(1, 1)
      expect(CompanyMetric.count).to eq(1)
    end

    it 'should created a new company_metric if does exist' do
      generate_company_metrics_for_network_in(1, 1)
      generate_company_metrics_for_network_in(1, 1)
      expect(CompanyMetric.count).to eq(1)
    end
  end

  describe 'cds_calculate_scores_for_generic_networks' do
    it 'should work' do
      allow(InteractAlgorithmsHelper).to receive(:calculate_network_indegree).and_return(
        [{'employee_id' => '1', 'score': '2'}, {'employee_id' => '2', 'score' => '3'}]
      )
      allow(InteractAlgorithmsHelper).to receive(:calculate_network_outdegree).and_return(
        [{'employee_id' => '1', 'score': '2'}, {'employee_id' => '5', 'score' => '6'}]
      )
      cds_calculate_scores_for_generic_networks(1,45)
      expect( CdsMetricScore.count ).to eq(8)
    end
  end
end
