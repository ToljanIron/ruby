require 'spec_helper'
require './app/helpers/mobile/questionnaire_questions_helper.rb'

describe Mobile::QuestionnaireQuestionsHelper do
  before do
    @c = Company.create!(name: "Acme")
    @q = Questionnaire.create!(name: "test", company_id: @c.id)
    @qq1 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 11, order: 1, min: 2)
    @qq2 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 12, order: 2, min: 2)
    @e1 = Employee.create!(company_id: @c.id, email: 'bb1@mail.com', first_name: 'Bb1', last_name: 'Qq1', external_id: 'bbb1')
    @e2 = Employee.create!(company_id: @c.id, email: 'bb2@mail.com', first_name: 'Bb2', last_name: 'Qq2', external_id: 'bbb2')
    @e3 = Employee.create!(company_id: @c.id, email: 'bb3@mail.com', first_name: 'Bb3', last_name: 'Qq3', external_id: 'bbb3')
    @qp1 = QuestionnaireParticipant.create(employee_id: @e1.id, questionnaire_id: @q.id)
    @qp2 = QuestionnaireParticipant.create(employee_id: @e2.id, questionnaire_id: @q.id)
    @qp3 = QuestionnaireParticipant.create(employee_id: @e3.id, questionnaire_id: @q.id)
    @qr1 = QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp2.id, reffered_questionnaire_participant_id: @qp1.id, answer: true)
    @qr2 = QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: true)
    @qr3 = QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq2.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: true)
    @qr4 = QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq2.id, questionnaire_participant_id: @qp2.id, reffered_questionnaire_participant_id: @qp1.id, answer: false)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  it 'servers as a runner' do
    #ret = Mobile::QuestionnaireQuestionsHelper.build_next_question_response(@qp1)
  end

end
