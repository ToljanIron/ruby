require 'spec_helper'
require './spec/spec_factory'

describe UiLevelConfigurationHelper, type: :helper do
  before do
    @cid = Company.create(name: 'testComp').id
    @workflow = UiLevelConfiguration.create(company_id: @cid, name:'Workflow', level: 1, display_order: 1)
    @top_talent = UiLevelConfiguration.create(company_id: @cid, name:'Top Talent', level: 1, display_order: 2)
    @influences = UiLevelConfiguration.create(company_id: @cid, name:'Influences', level: 2, display_order: 1, parent_id: @workflow.id)
    @alignment = UiLevelConfiguration.create(company_id: @cid, name:'alignment', level: 2, display_order: 2, parent_id: @workflow.id)
    @proportion = UiLevelConfiguration.create(company_id: @cid, name:'proportion', level: 3, display_order: 1, parent_id: @influences.id)
    @political_power = UiLevelConfiguration.create(company_id: @cid, name:'political power', level: 4, display_order: 1, parent_id: @proportion.id)
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end
  describe 'all_children_for_node' do
    it 'should return the tree of the ui level, which includes the row relevant values + 1 children array' do
      res = all_children_for_node(@workflow.id, 'color')
      expect(res.length).to eq(12)
      expect(res[:id]).to eq(@workflow.id)
      expect(res[:children][0][:id]).to eq(@influences.id)
    end
  end

  describe 'build_ui_level_tree' do
    it 'should return the tree of the ui level' do
      res = build_ui_level_tree(@cid)
      expect(res[:children].length).to eq(2)
      expect(res[:children][0][:id]).to eq(@workflow.id)
      expect(res[:children][1][:id]).to eq(@top_talent.id)
    end
  end

  describe 'build_ui_level_questionnaire_only' do
    describe 'generate_l4s_for_questionnaire_only' do
      res = nil
      before do
        NetworkName.create!(id: 1, name: 'net1', company_id: 1)
        NetworkName.create!(id: 2, name: 'net2', company_id: 1)
        Algorithm.create!(id: 601, name: 'In',  algorithm_type_id: 8)
        Algorithm.create!(id: 602, name: 'Out', algorithm_type_id: 8)
        Algorithm.create!(id: 603, name: 'Qq1', algorithm_type_id: 6)
        Algorithm.create!(id: 604, name: 'Qq2', algorithm_type_id: 6)
        CompanyMetric.create!(id: 1, company_id: 1, network_id: 1, algorithm_id: 601, algorithm_type_id: 8)
        CompanyMetric.create!(id: 2, company_id: 1, network_id: 1, algorithm_id: 602, algorithm_type_id: 8)
        CompanyMetric.create!(id: 3, company_id: 1, network_id: 2, algorithm_id: 601, algorithm_type_id: 8)
        CompanyMetric.create!(id: 4, company_id: 1, network_id: 2, algorithm_id: 602, algorithm_type_id: 8)
        CompanyMetric.create!(id: 5, company_id: 1, network_id: 1, algorithm_id: 1,   algorithm_type_id: 5)
        CompanyMetric.create!(id: 6, company_id: 1, network_id: 1, algorithm_id: 2,   algorithm_type_id: 5)

        res = generate_l4s_for_questionnaire_only(1)
      end

      it 'should twice the number of networks' do
        expect(res.length).to eq(4)
      end

      it 'should indicate indegree for in measures' do
        expect(res[0][:name]).to include('In')
      end

      it 'should indicate outdegree for in measures' do
        expect(res[3][:name]).to include('Out')
      end

      it 'should have increasing display order' do
        res = generate_l4s_for_questionnaire_only(1)
        expect(res[2][:display_order] > res[1][:display_order]).to be_truthy
      end

      describe 'check nested levels' do
        res = nil
        before do
          res = build_ui_level_questionnaire_only(1)
        end

        it 'should return 4 level 1 graphs' do
          expect(res[:children].length).to eq(4);
        end

        it 'should return 1 level 2 graphs' do
          expect(res[:children][3][:children].length).to eq(1);
        end

        it 'should return 1 level 3 graphs' do
          expect(res[:children][3][:children][0][:children].length).to eq(1);
        end

        it 'should return 4 level 4 graphs' do
          expect(res[:children][3][:children][0][:children][0][:children].length).to eq(4);
        end
      end
    end
  end
end
