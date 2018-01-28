require 'spec_helper'

describe Questionnaire, type: :model do
  before do
    @comp = Company.create(name: 'test-company')
    @questionnaire = Questionnaire.create(company_id: @comp.id, state: :notstarted, name:'test-name', pending_send:'')
    @e1 = Employee.create!(email: 'e1@mail.com', company_id: @comp.id, first_name: 'E', last_name: 'e', color_id: 1, external_id: 21)
    @e2 = Employee.create!(email: 'e2@mail.com', company_id: @comp.id, first_name: 'E', last_name: 'e', color_id: 1, external_id: 22)
    @e3 = Employee.create!(email: 'e3@mail.com', company_id: @comp.id + 1, first_name: 'E', last_name: 'e', color_id: 1, external_id: 23)
    @e4 = Employee.create!(email: 'e4@mail.com', company_id: @comp.id + 1, first_name: 'E', last_name: 'e', color_id: 2, external_id: 44)
    @question = Question.create(company_id: @comp.id, title: 'this is a test question', body: 'sdfasdf', active: true)
    @questionnair_question = QuestionnaireQuestion.create(questionnaire_id: @questionnaire.id, question_id: @question.id, company_id: @comp.id, title: 'this is a test question', body: 'sdfasdf', active: true)
    @question_recipient1 = QuestionnaireParticipant.create!(employee_id: @e1.id, questionnaire_id: @questionnaire.id, status: :completed)
    @question_recipient2 = QuestionnaireParticipant.create!(employee_id: @e2.id, questionnaire_id: @questionnaire.id, status: :completed)
    @question_recipient3 = QuestionnaireParticipant.create!(employee_id: @e3.id, questionnaire_id: @questionnaire.id, active: false)
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'prepare_for_send' do
    it 'should create 0 question replies for all workers when pending send has unstarted argument' do
      @questionnaire.update(pending_send: 'unstarted|email')
      @questionnaire.prepare_for_send
      expect(QuestionReply.count).to eq 0
      expect(@questionnaire.state).to eq('notstarted')
    end
    it 'should create 0 question replies for all workers when pending send has started argument' do
      @questionnaire.update(pending_send: 'started|email')
      QuestionReply.create(questionnaire_id: @questionnaire.id, questionnaire_question_id: @questionnair_question.id, questionnaire_participant_id: @question_recipient1.id, reffered_questionnaire_participant_id: @question_recipient2.id)
      @questionnaire.prepare_for_send
      expect(QuestionReply.count).to eq 1
      expect(@questionnaire.state).to eq('notstarted')
    end
  end

  describe 'resend_questionnaire' do
    before do
      EmailMessage.create!(questionnaire_participant_id: @question_recipient1.id, pending: false, message: 'Stam')
      EmailMessage.create!(questionnaire_participant_id: @question_recipient2.id, pending: false, message: 'Stam')
      EmailMessage.create!(questionnaire_participant_id: @question_recipient3.id, pending: false, message: 'Stam')
    end
    it 'should send only to employees who did not complete their questionnaire' do
      @questionnaire.resend_questionnaire_to_incomplete
      expect(EventLog.count).to eq(2)
    end
  end
end
