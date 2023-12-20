require 'spec_helper'

describe Questionnaire, type: :model do
  before do
    @comp = Company.create(name: 'test-company')
    @questionnaire = Questionnaire.create!(company_id: @comp.id, state: :notstarted, name:'test-name', pending_send:'')
    @snowball_questionnaire = Questionnaire.create!(company_id: @comp.id, state: :notstarted, name:'test-name1', pending_send:'',is_snowball_q:true)
    @group=Group.create!(company:@comp,snapshot_id:@questionnaire.snapshot_id,name:'test group')

    @e1 = Employee.create!(email: 'e1@mail.com', company_id: @comp.id, first_name: 'E', last_name: 'e', color_id: 1, external_id: 21,snapshot_id:@questionnaire.snapshot_id)
    @e2 = Employee.create!(email: 'e2@mail.com', company_id: @comp.id, first_name: 'E', last_name: 'e', color_id: 1, external_id: 22)
    @e3 = Employee.create!(email: 'e3@mail.com', company_id: @comp.id + 1, first_name: 'E', last_name: 'e', color_id: 1, external_id: 23)
    @e4 = Employee.create!(email: 'e4@mail.com', company_id: @comp.id + 1, first_name: 'E4F', last_name: 'E4L', color_id: 2, external_id: 44,group_id:@group.id,snapshot_id:@questionnaire.snapshot_id)
    @question = Question.create(company_id: @comp.id, title: 'this is a test question', body: 'sdfasdf', active: true)
    @questionnair_question = QuestionnaireQuestion.create(questionnaire_id: @questionnaire.id, question_id: @question.id, company_id: @comp.id, title: 'this is a test question', body: 'sdfasdf', active: true)
    @qpid = QuestionnaireParticipant.create!(employee_id: @e1.id, questionnaire_id: @questionnaire.id, status: :completed)
    @question_recipient2 = QuestionnaireParticipant.create!(employee_id: @e2.id, questionnaire_id: @questionnaire.id, status: :completed)
    @question_recipient3 = QuestionnaireParticipant.create!(employee_id: @e3.id, questionnaire_id: @questionnaire.id, active: false)
    
    @sbquestionnair_question = QuestionnaireQuestion.create(questionnaire_id: @snowball_questionnaire.id, question_id: @question.id, company_id: @comp.id, title: 'this is a test question', body: 'sdfasdf', active: true)
    @sbquestion_recipient1 = QuestionnaireParticipant.create!(employee_id: @e1.id, questionnaire_id: @snowball_questionnaire.id, status: :completed)
    @sbquestion_recipient2 = QuestionnaireParticipant.create!(employee_id: @e2.id, questionnaire_id: @snowball_questionnaire.id, status: :completed)
    @sbquestion_recipient3 = QuestionnaireParticipant.create!(employee_id: @e3.id, questionnaire_id: @snowball_questionnaire.id, active: false)
    @sbquestion_recipient4 = QuestionnaireParticipant.create!(employee_id: @e4.id, questionnaire_id: @snowball_questionnaire.id, active: true,is_verified:true)
   
    @user = User.create!(permissible_group: 'g2', id: 999, company_id: @comp.id, role: :admin, password: '12341324', email: 'r@q.com')

  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'get_all_questionnaires' do
    it 'should work' do
      res = Questionnaire.get_all_questionnaires(@comp.id,@user)
      expect( res[0]['stats'] ).to eq([2,nil,nil,2])
      expect( res[0]['email_subject'] ).to eq('StepAhead questionnaire')
    end
  end
  describe 'create_unverified_participant_employee' do
    it 'should work' do
      params={qpid:@sbquestion_recipient1.id,e_group:@group.id,e_first_name:'joe',e_last_name:'smith'}
      res = Questionnaire.create_unverified_participant_employee(params)
      expect(res[:msg]).to be_empty
      expect(res[:employee][:first_name]).to eq('joe')
      expect(res[:employee][:last_name]).to eq('smith')
      expect QuestionnaireParticipant.last.snowballer_employee_id== @sbquestion_recipient1.id
    end
    it 'sohuld return an existing participant' do
      params={qpid:@sbquestion_recipient1.id,e_group:@group.id,e_first_name:'E4F',e_last_name:'E4L'}
      res = Questionnaire.create_unverified_participant_employee(params)
      expect(res[:msg]).to be_empty
      expect(res[:employee][:first_name]).to eq('E4F')
      expect(res[:employee][:last_name]).to eq('E4L')
      expect(res[:employee][:id]).to eq(@e4.id)
      expect(res[:qpid]).to eq(@sbquestion_recipient4.id)
      
      expect QuestionnaireParticipant.last.snowballer_employee_id== @sbquestion_recipient1.id
    end
  end
end
