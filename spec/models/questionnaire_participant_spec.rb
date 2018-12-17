require 'spec_helper'
include FactoryBot::Syntax::Methods

describe QuestionnaireParticipant, type: :model do
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'filter_only_relevant_qp' do
    let(:emp) { create(:employee, id: 0) }

    it 'should return automatically formed connections if configuration table says so' do
      CompanyConfigurationTable.create(key: 'populate_questionnaire_automatically', value: 'true', comp_id: 1)
      qp = QuestionnaireParticipant.create(employee_id: emp.id, questionnaire_id: 1)
      qq = QuestionnaireQuestion.create(company_id: 1, question_id: 1, questionnaire_id: 1)
      qp_arr = []
      (1..3).each do |id|
        new_qp = QuestionnaireParticipant.create(employee_id: id, questionnaire_id: 1)
        qp_arr << new_qp.id
        EmployeesConnection.create(employee_id: emp.id, connection_id: id)
      end
      expect(qp.filter_only_relevant_qp(qq)).to eq([2, 3, 4])
    end

    it 'should return participants who were picked in a question given one depends on' do
      qp = QuestionnaireParticipant.create(employee_id: emp.id)
      indep_qq = QuestionnaireQuestion.create(company_id: 1, question_id: 1, questionnaire_id: 1, order: 1)
      depen_qq = QuestionnaireQuestion.create(company_id: 1, question_id: 2, questionnaire_id: 1, order: 2, depends_on_question: indep_qq[:order])
      (11..13).each do |id|
        QuestionReply.create(
          questionnaire_question_id: indep_qq.id,
          questionnaire_id: 1,
          questionnaire_participant_id: qp.id,
          reffered_questionnaire_participant_id: id,
          answer: true
        )
      end
      expect(qp.filter_only_relevant_qp(depen_qq).length).to eq(3)
      expect(qp.filter_only_relevant_qp(depen_qq)).to include(11)
      expect(qp.filter_only_relevant_qp(depen_qq)).to include(12)
      expect(qp.filter_only_relevant_qp(depen_qq)).to include(13)
    end
  end

  describe 'update_questionnaire_participant_status' do
    it "should return in_process if equal  to 'in process'" do
      res = QuestionnaireParticipant.update_questionnaire_participant_status('in process', 2)
      expect(res).to be :in_process
    end

    it "should return entered if equal  to 'in process' and the current_question is  1" do
      res = QuestionnaireParticipant.update_questionnaire_participant_status('in process', 1)
      expect(res).to be :entered
    end

    it "should return completed if equal  to 'done'" do
      res = QuestionnaireParticipant.update_questionnaire_participant_status('done', 4)
      expect(res).to be :completed
    end

    it "should return entered if equal  to 'first time'" do
      res = QuestionnaireParticipant.update_questionnaire_participant_status('first time', 1)
      expect(res).to be :entered
    end

    it "should return entered is 'done' and number of questions is not 1 " do
      res = QuestionnaireParticipant.update_questionnaire_participant_status('done', 1, -1)
      expect(res).to be :entered
    end

    it "should return completed is 'done' and number of questions is 1 " do
      res = QuestionnaireParticipant.update_questionnaire_participant_status('done', 1, 1)
      expect(res).to be :completed
    end
  end

  describe 'update_replies' do
    before do
      @qp = QuestionnaireParticipant.new(questionnaire_id: 11)
      @r = [{ e_id: 1, answer: true }]
      @qp.stub(:find_questionnaire_question) { QuestionnaireQuestion.new(id: 22) }
    end

    it 'should create a new answer if none exists' do
      expect(QuestionReply.count).to be(0)
      @qp.update_replies(@r)
      expect(QuestionReply.count).to be(1)
      expect(QuestionReply.first[:answer]).to be(true)
    end

    it 'should not create a new answer if same one exists' do
      expect(QuestionReply.count).to be(0)
      @qp.update_replies(@r)
      expect(QuestionReply.count).to be(1)
      @qp.update_replies(@r)
      expect(QuestionReply.count).to be(1)
    end

    it 'should only change answer if new answer is different' do
      @qp.update_replies(@r)
      expect(QuestionReply.count).to be(1)
      @r = [{ e_id: 1, answer: false }]
      @qp.update_replies(@r)
      expect(QuestionReply.count).to be(1)
      expect(QuestionReply.first[:answer]).to be(false)
    end

    it 'should add a new record if does not exist' do
      @qp.update_replies(@r)
      expect(QuestionReply.count).to be(1)
      @r = [{ e_id: 2, answer: false }]
      @qp.update_replies(@r)
      expect(QuestionReply.count).to be(2)
    end

    it 'should create a new recored to reply when the questionnaire participant(e_id) not exist' do
      # @qp.update_attribute(:employee_id, 30)
      qp_for_employee_not_in_list = QuestionnaireParticipant.create!(questionnaire_id: @qp.questionnaire_id, employee_id: 30)
      r_without_qp = [{ employee_details_id: 30, e_id: nil, answer: true }]
      @qp.update_replies(r_without_qp)
      expect(QuestionReply.count).to be(1)
      expect(QuestionReply.last.reffered_questionnaire_participant_id).to be(qp_for_employee_not_in_list.id)
    end
  end

  describe 'test find_next_question' do
    before do
      @c   = Company.create!(name: 'Acme')
      @q   = Questionnaire.create!(name: "test", company_id: @c.id)
      @e1  = Employee.create!(company_id: @c.id, email: 'bb1@mail.com', first_name: 'Bb1', last_name: 'Qq1', external_id: 'bbb1')
      @e2  = Employee.create!(company_id: @c.id, email: 'bb2@mail.com', first_name: 'Bb2', last_name: 'Qq2', external_id: 'bbb2')
      @e3  = Employee.create!(company_id: @c.id, email: 'bb3@mail.com', first_name: 'Bb3', last_name: 'Qq3', external_id: 'bbb3')
      @qp1 = QuestionnaireParticipant.create(employee_id: @e1.id, questionnaire_id: @q.id)
      @qp2 = QuestionnaireParticipant.create(employee_id: @e2.id, questionnaire_id: @q.id)
      @qp3 = QuestionnaireParticipant.create(employee_id: @e3.id, questionnaire_id: @q.id)
    end

    describe 'with no dependent questions' do
      before(:each) do
        @qq1 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 11, order: 1, min: 2, active: true)
        @qq2 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 12, order: 2, min: 2, active: true)
        @qr2 = QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: true)
        @qr3 = QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq2.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: true)
      end

      it 'Should return the first question' do
        qq, status = @qp1.find_next_question
        expect( status ).to eq('in process')
        expect( qq.id ).to eq(1)
      end

      it 'Should return the second question' do
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp3.id, answer: true)
        qq, status = @qp1.find_next_question
        expect( status ).to eq('in process')
        expect( qq.id ).to eq(2)
      end

      it 'Should return done' do
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp3.id, answer: true)
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq2.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp3.id, answer: true)
        qq, status = @qp1.find_next_question
        expect( status ).to eq('done')
        expect( qq ).not_to be_nil
      end
    end

    describe 'with no dependent questions' do
      before(:each) do
        @qq1 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id,                 order: 1, min: 2, active: true)
        @qq2 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 12, order: 2,         active: true, depends_on_question: @qq1.id)
        @qr1 = QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: true)
      end

      it 'Should return the first question' do
        qq, status = @qp1.find_next_question
        expect( status ).to eq('in process')
        expect( qq.id ).to eq(1)
      end

      it 'Should return the second, dependent, question in porcess' do
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp3.id, answer: true)
        qq, status = @qp1.find_next_question
        expect( status ).to eq('in process')
        expect( qq.id ).to eq(2)
      end

      it 'Should return the second, dependent, question in porcess even with one answer' do
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp3.id, answer: true)
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq2.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: true)
        byebug
        qq, status = @qp1.find_next_question
        expect( status ).to eq('in process')
        expect( qq.id ).to eq(2)
      end

      it 'Should return done' do
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq1.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp3.id, answer: true)
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq2.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: true)
        QuestionReply.create!(questionnaire_id: @q.id, questionnaire_question_id: @qq2.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp3.id, answer: true)
        qq, status = @qp1.find_next_question
        expect( status ).to eq('done')
        expect( qq ).not_to be_nil
      end
    end
  end

  describe 'create_link' do
    it 'should create a legal link' do
      qp = QuestionnaireParticipant.new
      url = qp.create_link
      expect(url).to match(/^http.*questionnaire\?token=[0-9a-zA-Z]+$/)
    end
  end
end
