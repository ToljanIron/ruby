require 'spec_helper'

describe Questionnaire, type: :model do
  before do
    @comp = Company.create(name: 'test-company')
    @questionnaire = Questionnaire.create!(company_id: @comp.id, state: :notstarted, name:'test-name', pending_send:'')
    @snowball_questionnaire = Questionnaire.create!(company_id: @comp.id, state: :notstarted, name:'test-name1', pending_send:'',is_snowball_q:true)

    @e1 = Employee.create!(email: 'e1@mail.com', company_id: @comp.id, first_name: 'E', last_name: 'e', color_id: 1, external_id: 21)
    @e2 = Employee.create!(email: 'e2@mail.com', company_id: @comp.id, first_name: 'E', last_name: 'e', color_id: 1, external_id: 22)
    @e3 = Employee.create!(email: 'e3@mail.com', company_id: @comp.id + 1, first_name: 'E', last_name: 'e', color_id: 1, external_id: 23)
    @e4 = Employee.create!(email: 'e4@mail.com', company_id: @comp.id + 1, first_name: 'E', last_name: 'e', color_id: 2, external_id: 44)
    @question = Question.create(company_id: @comp.id, title: 'this is a test question', body: 'sdfasdf', active: true)
    
    @questionnair_question = QuestionnaireQuestion.create(questionnaire_id: @questionnaire.id, question_id: @question.id, company_id: @comp.id, title: 'this is a test question', body: 'sdfasdf', active: true)
    @question_recipient1 = QuestionnaireParticipant.create!(employee_id: @e1.id, questionnaire_id: @questionnaire.id, status: :completed)
    @question_recipient2 = QuestionnaireParticipant.create!(employee_id: @e2.id, questionnaire_id: @questionnaire.id, status: :completed)
    @question_recipient3 = QuestionnaireParticipant.create!(employee_id: @e3.id, questionnaire_id: @questionnaire.id, active: false)
    
    @sbquestionnair_question = QuestionnaireQuestion.create(questionnaire_id: @snowball_questionnaire.id, question_id: @question.id, company_id: @comp.id, title: 'this is a test question', body: 'sdfasdf', active: true)
    @sbquestion_recipient1 = QuestionnaireParticipant.create!(employee_id: @e1.id, questionnaire_id: @snowball_questionnaire.id, status: :completed)
    @sbquestion_recipient2 = QuestionnaireParticipant.create!(employee_id: @e2.id, questionnaire_id: @snowball_questionnaire.id, status: :completed)
    @sbquestion_recipient3 = QuestionnaireParticipant.create!(employee_id: @e3.id, questionnaire_id: @snowball_questionnaire.id, active: false)


    @user = User.create!(permissible_group: 'g2', id: 999, company_id: @comp.id, role: :admin, password: '12341324', email: 'r@q.com')

  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'get_all_questionnaires' do
    it 'should work' do
      res = Questionnaire.get_all_questionnaires(@comp.id,@user)
      expect( res[0]['stats'] ).to eq([1,nil,nil,2])
      expect( res[0]['email_subject'] ).to eq('StepAhead questionnaire')
      
      expect( res[0]['is_snowball_q'] ).to eq(1)
      
      expect( res[1]['is_snowball_q'] ).to eq(0)

    end
  end
end
