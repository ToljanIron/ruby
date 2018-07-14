require 'spec_helper'
require './app/helpers/mobile/questionnaire_helper.rb'
require './app/helpers/mobile/csv_loader.rb'

describe Mobile::QuestionnaireHelper do
  before do
    @src_digital_israel = './spec/helpers/digital-israel.csv'
    @src_target_digital_israel = []
    CSV.foreach(@src_digital_israel, :headers => false) do |row|
      @src_target_digital_israel.push(row)
    end
    @csv_target_advice = CSV.open("./spec/helpers/advice.csv", 'w')
    @advice_header = ["employee", "advicee", "advice_flag", "snapshot"]
    @trust_header = ["employee", "trusted", "trust_flag", "snapshot"]
    @csv_target_trust = CSV.open("./spec/helpers/trust.csv", 'w')
    @questions_lines = [0, 5, 10]
    @questions_type = ['advice', 'trust', 'advice']
    @snapshot_dates = ['2015-01-01', '2015-01-01', '2015-01-02']
    @employess = ['hadas@spectory.com', 'vali@spectory.com']
    @questions = [[["yaniv@spectory.com", "vali@spectory.com", 1, "2015-01-01"]], [["yaniv@spectory.com", "hadas@spectory.com", 1, "2015-01-01"]], [["yaniv@spectory.com", "hadas@spectory.com", 1, "2015-01-02"]]]
    @questions_for_write = [[["yaniv@spectory.com", "vali@spectory.com", '1', "2015-01-01"]], [["yaniv@spectory.com", "hadas@spectory.com", '1', "2015-01-01"]], [["yaniv@spectory.com", "hadas@spectory.com", '1', "2015-01-02"]]]
  end

  after do
     DatabaseCleaner.clean_with(:truncation)
     Dir["#{Rails.root}/spec/helpers/advice.csv"].each do |file|
       File.delete(file)
     end
     Dir["#{Rails.root}/spec/helpers/trust.csv"].each do |file|
       File.delete(file)
     end
  end

  it 'should create headers for the csv files' do
    @csv_target_advice = CSV.open("./spec/helpers/advice.csv", 'a+')
    @csv_target_advice << ["employee", "advicee", "advice_flag", "snapshot"]
    @csv_target_advice.close
    src = []
    CSV.foreach('./spec/helpers/advice.csv', :headers => false) do |row|
      src.push(row)
    end
    expect(src[0]).to eql(@advice_header)
    @csv_target_trust = CSV.open("./spec/helpers/trust.csv", 'a+')
    @csv_target_trust << ["employee", "trusted", "trust_flag", "snapshot"]
    @csv_target_trust.close
    src = []
    CSV.foreach('./spec/helpers/trust.csv', :headers => false) do |row|
      src.push(row)
    end
    expect(src[0]).to eql(@trust_header)
  end

  it 'should return questions line' do
    ans = Mobile::QuestionnaireHelper.get_questions_lines(@src_target_digital_israel)
    expect(ans).to eql(@questions_lines)
  end

  it 'should return questions type' do
    type = []
    @questions_lines.each do |index|
      ans = Mobile::QuestionnaireHelper.get_question_type(@src_target_digital_israel, index)
      type.push(ans)
    end
    expect(type).to eql(@questions_type)
  end

  it 'should return snapshot date' do
    date = []
    @questions_lines.each do |index|
      ans = Mobile::QuestionnaireHelper.get_snapshot_date(@src_target_digital_israel, index)
      date.push(ans)
    end
    expect(date).to eql(@snapshot_dates)
  end

  it 'should get_csv_question' do
    questions = []
    @questions_lines.each_with_index do |index_questions, index|
      ans = Mobile::QuestionnaireHelper.get_csv_question(@src_target_digital_israel, @snapshot_dates[index], @employess, index_questions)
      questions.push(ans)
    end
    expect(questions).to eql(@questions)
  end

  it 'should write_question_to_csv' do
    @questions_lines.each_with_index do |index_questions, index|
      Mobile::QuestionnaireHelper.write_question_to_csv(@questions[index], './spec/helpers/' + @questions_type[index])
    end
    src = []
    CSV.foreach('./spec/helpers/advice.csv', :headers => false) do |row|
      src.push(row)
    end
    expect(src[0]).to eql(@questions_for_write[0][0])
    expect(src[1]).to eql(@questions_for_write[2][0])
    src = []
    CSV.foreach('./spec/helpers/trust.csv', :headers => false) do |row|
      src.push(row)
    end
    expect([src[0]]).to eql(@questions_for_write[1])
  end

  describe 'create_questionnaire' do

    before do
      Employee.create!(company_id: 2, email: 'aa@mail.com', first_name: 'Aa', last_name: 'Qq', external_id: 'aaa')
      Employee.create!(company_id: 2, email: 'bb@mail.com', first_name: 'Bb', last_name: 'Qq', external_id: 'bbb')
      Question.create!(company_id: 2, title: 'qqq1')
      Question.create!(company_id: 2, title: 'qqq2')
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should create a new quesitonnaire' do
      Mobile::QuestionnaireHelper.create_questionnaire(2, 'Test Questionnaire')
      expect(Questionnaire.first.state).to eq('created')
      expect(QuestionnaireQuestion.count).to eq(2)
      expect(QuestionnaireParticipant.count).to eq(2)
    end

    it 'should return all quesions from the specific questionnaire' do
      qq = Mobile::QuestionnaireHelper.create_questionnaire(2, 'Test Questionnaire')
      QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: 99, question_id: 99)
      questions = Mobile::QuestionnaireHelper.list_questionnaire_questions(qq.id)
      expect(questions.count).to eq (2)
    end

    it 'should create questions.all.count questionnair_questions for questionnaire' do
      qq = Mobile::QuestionnaireHelper.create_questionnaire(3, 'Test Questionnaire')
      questions = Mobile::QuestionnaireHelper.list_questionnaire_questions(qq.id)
      expect(questions.count).to eq(2)
    end

    it 'should handle gracefully nonexistant questionnaire' do
      expect{ Mobile::QuestionnaireHelper.list_questionnaire_questions(33) }.not_to raise_error
    end
  end

  describe 'set_active_questions' do
    before do
      @q1 = Question.create!(company_id: 2, title: 'qqq1')
      @q2 = Question.create!(company_id: 2, title: 'qqq2')
      @q3 = Question.create!(company_id: 2, title: 'qqq3')
      @q4 = Question.create!(company_id: 2, title: 'qqq4')
      @quest = Mobile::QuestionnaireHelper.create_questionnaire(2, 'Test Questionnaire')
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should include only active questions' do
      Mobile::QuestionnaireHelper.set_active_questions(@quest.id, [@q1.id, @q3.id, @q4.id])
      questions = QuestionnaireQuestion.where(questionnaire_id: @quest.id, active: true)
      expect(questions.count).to eq(3)
    end

    it 'should include all questions' do
      Mobile::QuestionnaireHelper.set_active_questions(@quest.id, [@q1.id,@q2.id, @q3.id, @q4.id])
      questions = QuestionnaireQuestion.where(questionnaire_id: @quest.id, active: true)
      expect(questions.count).to eq(4)
    end

    it 'should handle empty input' do
      Mobile::QuestionnaireHelper.set_active_questions(@quest.id, [])
      questions = QuestionnaireQuestion.where(questionnaire_id: @quest.id, active: true)
      expect(questions.count).to eq(0)
    end
  end

  describe 'employees' do
    before do
      @e1 = Employee.create!(company_id: 2, email: 'bb1@mail.com', first_name: 'Bb1', last_name: 'Qq1', external_id: 'bbb1')
      @e2 = Employee.create!(company_id: 2, email: 'bb2@mail.com', first_name: 'Bb2', last_name: 'Qq2', external_id: 'bbb2')
      @e3 = Employee.create!(company_id: 2, email: 'bb3@mail.com', first_name: 'Bb3', last_name: 'Qq3', external_id: 'bbb3')
      @e4 = Employee.create!(company_id: 2, email: 'bb4@mail.com', first_name: 'Bb4', last_name: 'Qq4', external_id: 'bbb4')
      @quest = Mobile::QuestionnaireHelper.create_questionnaire(2, 'Test Questionnaire' )
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should list all employees in the questionnaire' do
      emps = Mobile::QuestionnaireHelper.list_questionnaire_emps(@quest.id)
      expect(emps.count).to be(4)
    end

    it 'should handle empty list ' do
      emps = Mobile::QuestionnaireHelper.list_questionnaire_emps(15)
      expect(emps.count).to be(0)
    end

    it 'should set number of active emps in questionnaire to 2' do
      Mobile::QuestionnaireHelper.set_active_employees(@quest.id, [@e2.id, @e3.id])
      employees = QuestionnaireParticipant.where(questionnaire_id: @quest.id, active: true)
      expect(employees.count).to eq(2)
    end
  end

  describe 'freeze_questionnaire_replies_in_snapshot' do
    before do
      @c = Company.create!(name: "Acme")
      @q = Questionnaire.create!(name: "test", company_id: @c.id)
      @qq1 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 11)
      @qq2 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 12)
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

    it 'should copy over all replies' do
      Mobile::QuestionnaireHelper.freeze_questionnaire_replies_in_snapshot(@q.id)
      expect(NetworkSnapshotData.count).to eq(4)
    end

    it 'should throw exception if there is no such questionnaire' do
      expect{Mobile::QuestionnaireHelper.freeze_questionnaire_replies_in_snapshot(99)}.to raise_error
    end

    it 'should create a new snapshot if does not exist' do
      Mobile::QuestionnaireHelper.freeze_questionnaire_replies_in_snapshot(@q.id)
      expect(Snapshot.count).to eq(1)
      expect(Snapshot.last.company_id).to eq(1)
    end

    it 'should not create a new snapshot if one already exists' do
      Mobile::QuestionnaireHelper.freeze_questionnaire_replies_in_snapshot(@q.id)
      @qr5 = QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq2.id, questionnaire_participant_id: 5, reffered_questionnaire_participant_id: 4, answer: true)
      Mobile::QuestionnaireHelper.freeze_questionnaire_replies_in_snapshot(@q.id)
      expect(Snapshot.count).to eq(1)
    end
  end

  describe 'get_questionnaire_details' do
    before do
      @c = Company.create!(name: "Acme")
      @q = Questionnaire.create!(name: "test", company_id: @c.id)
      @e1 = Employee.create!(company_id: @c.id, email: 'bb1@mail.com', first_name: 'Bb1', last_name: 'Qq1', external_id: 'bbb1')
      @e2 = Employee.create!(company_id: @c.id, email: 'bb2@mail.com', first_name: 'Bb2', last_name: 'Qq2', external_id: 'bbb2')
      @e3 = Employee.create!(company_id: @c.id, email: 'bb3@mail.com', first_name: 'Bb3', last_name: 'Qq3', external_id: 'bbb3')
      @qp = QuestionnaireParticipant.create!(employee_id: @e1.id, questionnaire_id: @q.id, active: true)
      @qp = QuestionnaireParticipant.create!(employee_id: @e2.id, questionnaire_id: @q.id, active: true)
      @qp = QuestionnaireParticipant.create!(employee_id: @e3.id, questionnaire_id: @q.id, active: false)
      @qq1 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 11)
      @qq2 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 12)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

	  it 'should get all questionnaire details' do
      ret = Mobile::QuestionnaireHelper.get_questionnaire_details(@q.id)
      expect(ret[:employees].count).to eq(3)
      expect(ret[:questions].count).to eq(2)
    end
  end

  describe 'update questionnaire name' do
    before do
      @c = Company.create!(name: "Acme")
      @q = Questionnaire.create!(name: "test with mistake", company_id: @c.id)
      @q1 = Questionnaire.create!(name: "bla bla", company_id: @c.id)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should change the name of the questionnaire' do
      Mobile::QuestionnaireHelper.update_questionnaire(@c.id, @q.id, 'fix name')
      expect(Questionnaire.first.name).to eq('fix name')
      expect(Questionnaire.last.name).not_to eq('fix name')
    end

    it 'should not change any name from Questionnaire' do
      Mobile::QuestionnaireHelper.update_questionnaire(@c.id, nil, 'fix name')
      expect(Questionnaire.first.name).to eq(@q.name)
      expect(Questionnaire.last.name).to eq(@q1.name)
    end
  end

end
