require 'spec_helper'
require './app/controllers/mobile/questionnaire_questions_controller.rb'
require './spec/spec_factory'

describe Mobile::QuestionnaireQuestionsController, type: :controller  do
  describe 'update questionnaire_question' do 
    before do 
      @c = Company.create!(name: "Acme")
      @q = Questionnaire.create!(name: "Questionnaire 1", company_id: @c.id)
      FactoryGirl.create(:network_name, name: 'advice')
      FactoryGirl.create(:network_name, name: 'friendships')
      @qq1 = FactoryGirl.create(:questionnaire_question)
      FactoryGirl.create(:questionnaire_question, questionnaire_id: 2)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end
    it 'should update the current Questionnaire Question to not active and change the network id to advice' do 
      log_in_with_dummy_user_with_role(2, 1)
      params = { order: 1, title: 'AA', body: 'bb', min: 0 , max: 20, active: false, network_id: 2, id: 1, questionnaire_id: 1}
      post :update_questionnaire_question, question: params
      expect(QuestionnaireQuestion.first.network_id).to eq(2)
      expect(QuestionnaireQuestion.first.active).to eq(false)
    end

    it 'should not update if the question not in current questionnaire ' do 
      log_in_with_dummy_user_with_role(2, 1)
      params = { order: 1, title: 'AA', body: 'bb', min: 0 , max: 5, active: false, network_id: 2, id: 1, questionnaire_id: 1}
      post :update_questionnaire_question, question: params
      expect(QuestionnaireQuestion.last.network_id).to_not eq(2)
      expect(QuestionnaireQuestion.last.active).to_not eq(false)
    end
  end

end