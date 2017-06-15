require 'spec_helper'
require './app/helpers/mobile/questionnaire_helper.rb'
require './app/helpers/mobile/csv_loader.rb'

describe Mobile::QuestionnaireHelper do
  before do
    company = Company.create(name: 'dummy')
    CsvLoader.csv_to_emps('./spec/helpers/CSV_test.csv', company.id)
    a = Employee.first
    a.current_question_id = 3
    a.save!
    @q1 = QuestionReply.create!(question_id: 1, employee_id: 1, reffered_employee_id: 30, answer: true)
    @q2 = QuestionReply.create!(question_id: 1, employee_id: 2, reffered_employee_id: 30, answer: true)
    @q3 = QuestionReply.create!(question_id: 1, employee_id: 3, reffered_employee_id: 30, answer: true)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  xit 'should get current_question_id -> nil for all emps' do
    Mobile::QuestionnaireHelper.delete_all_replies
    Employee.all.each do |e|
      expect(e.current_question_id).to eql(nil)
    end
  end

  xit 'should get answer -> nil for all questionReplies' do
    Mobile::QuestionnaireHelper.delete_all_replies
    QuestionReply.all.each do |qr|
      expect(qr.answer).to eql(nil)
    end
  end
end
