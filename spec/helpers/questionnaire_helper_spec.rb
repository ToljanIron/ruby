require 'spec_helper'

describe QuestionnaireHelper, type: :helper do

  before do
    @c = Company.create!(name: "Acme")
    @q = Questionnaire.create!(name: "test", company_id: @c.id, state: 'sent')

    @e1 = Employee.create!(id: 11, company_id: @c.id, email: 'bb1@mail.com', first_name: 'Bb1', last_name: 'Qq1', external_id: 'bbb1')
    @e2 = Employee.create!(id: 12, company_id: @c.id, email: 'bb2@mail.com', first_name: 'Bb2', last_name: 'Qq2', external_id: 'bbb2')
    @e3 = Employee.create!(id: 13, company_id: @c.id, email: 'bb3@mail.com', first_name: 'Bb3', last_name: 'Qq3', external_id: 'bbb3')
    @e4 = Employee.create!(id: 14, company_id: @c.id, email: 'bb4@mail.com', first_name: 'Bb4', last_name: 'Qq4', external_id: 'bbb4')
    @e5 = Employee.create!(id: 15, company_id: @c.id, email: 'bb5@mail.com', first_name: 'Bb5', last_name: 'Qq5', external_id: 'bbb5')
    @e6 = Employee.create!(id: 16, company_id: @c.id, email: 'bb6@mail.com', first_name: 'Bb6', last_name: 'Qq6', external_id: 'bbb6')

    @qp1 = QuestionnaireParticipant.create!(employee_id: @e1.id, questionnaire_id: @q.id, active: true, token: 't1')
    @qp2 = QuestionnaireParticipant.create!(employee_id: @e2.id, questionnaire_id: @q.id, active: true, token: 't2')
    @qp3 = QuestionnaireParticipant.create!(employee_id: @e3.id, questionnaire_id: @q.id, active: true, token: 't3')
    @qp4 = QuestionnaireParticipant.create!(employee_id: @e4.id, questionnaire_id: @q.id, active: true, token: 't4')
    @qp5 = QuestionnaireParticipant.create!(employee_id: @e5.id, questionnaire_id: @q.id, active: true, token: 't5')
    @qp6 = QuestionnaireParticipant.create!(employee_id: @e6.id, questionnaire_id: @q.id, active: true, token: 't6')
    @qp7 = QuestionnaireParticipant.create!(employee_id: -1, questionnaire_id: @q.id, active: true,     token: 't7', participant_type: 'tester')

    @qq1 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 11, active: true, order: 1, min: 2, max: 4)
    @qq2 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 12, active: true, order: 2)
    @qq3 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 13, active: true, order: 3)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'find_and_fix_cold_questionnaires' do
    it 'should fix a cold questionnaire' do
      add_question_reply(@qq3.id, @qp1.id, @qp2.id, true, 3.days.ago)
      add_question_reply(@qq3.id, @qp1.id, @qp3.id, true, 3.days.ago)
      add_question_reply(@qq3.id, @qp1.id, @qp4.id, true, 3.days.ago)
      @qp1.update(status: :in_process)
      QuestionnaireHelper.find_and_fix_cold_questionnaires
      qp1 = QuestionnaireParticipant.find(@qp1.id)
      expect( qp1.status ).to eq('completed')
    end

    it 'should not fix a questionnaire where the last question was not answered at all' do
      add_question_reply(@qq2.id, @qp1.id, @qp2.id, true, 3.days.ago)
      add_question_reply(@qq2.id, @qp1.id, @qp3.id, true, 3.days.ago)
      add_question_reply(@qq2.id, @qp1.id, @qp4.id, true, 3.days.ago)
      @qp1.update(status: :in_process)
      QuestionnaireHelper.find_and_fix_cold_questionnaires
      qp1 = QuestionnaireParticipant.find(@qp1.id)
      expect( qp1.status ).to eq('in_process')
    end

    it 'should not fix a questionnaire where the last question was answered today' do
      add_question_reply(@qq1.id, @qp1.id, @qp2.id, true, 5.hours.ago)
      add_question_reply(@qq1.id, @qp1.id, @qp3.id, true, 5.hours.ago)
      add_question_reply(@qq1.id, @qp1.id, @qp4.id, true, 5.hours.ago)
      @qp1.update(status: :in_process)
      QuestionnaireHelper.find_and_fix_cold_questionnaires
      qp1 = QuestionnaireParticipant.find(@qp1.id)
      expect( qp1.status ).to eq('in_process')
    end
  end

  describe 'get_questionnaire_details' do
	  it 'should get all questionnaire details' do
      res = get_questionnaire_details('t2')
      expect( res[:q_state] ).to eq('sent')
      expect( res[:qp_state] ).to eq('entered')
      expect( res[:questionnaire_id] ).to eq(@q.id)
      expect( res[:total_questions] ).to eq(3)
    end

    it 'should raise exception if participant does not exsit' do
      expect{ get_questionnaire_details('t11') }.to raise_error(RuntimeError, 'Not found participant with token: t11')
    end

    it 'should get correct position of question' do
      @qp2.update!(current_questiannair_question_id: @qq2.id)
      res = get_questionnaire_details('t2')
      expect( res[:current_question_position] ).to eq(2)
    end

    context 'where there are inactive questions' do
      it 'should get correct position of question' do
        @qp2.update!(current_questiannair_question_id: @qq3.id)
        @qq2.update!(active: false)
        res = get_questionnaire_details('t2')
        expect( res[:current_question_position] ).to eq(2)
      end
    end

    context 'first time enter' do
      it 'should update participant status and current question' do
        res = get_questionnaire_details('t2')
        ## This line is not as dumb as it looks, @qp2's DB state has chagned
        ##   In the previous line and thus should be reloaded.
        @qp2 = QuestionnaireParticipant.find(@qp2.id)
        expect( @qp2.status ).to eq('entered')
        expect( @qp2.current_questiannair_question_id ).to eq(@qq1.id)
        expect( res[:qp_state] ).to eq('entered')
        expect( res[:question_id] ).to eq(@qq1.id)
      end
    end
  end

  describe 'get_question_participants' do

    context 'in funnel question when not using automatic employee_connection' do
      before do
        @qq1.update!(is_funnel_question: true)
        @q.update!(use_employee_connections: false)
      end

      it 'should return all employees with answer nil' do
        ret = get_question_participants('t1')[:replies]
        qps_with_answer_nil = ret.select { |r| r[:answer].nil? }
        expect( qps_with_answer_nil.length ).to eq (5)
      end

      context 'when there are already some replies' do
        before do
          add_question_reply(@qq1.id, @qp1.id, @qp2.id, true)
          add_question_reply(@qq1.id, @qp1.id, @qp3.id, false)
        end

        it 'should return some employees with answer nil and some with numbers' do
          ret = get_question_participants('t1')[:replies]

          expect( find_by_qp(ret, 2)[:answer] ).to eq(true)
          expect( find_by_qp(ret, 3)[:answer] ).to eq(false)
          expect( find_by_qp(ret, 4)[:answer] ).to be_nil
          expect( find_by_qp(ret, 5)[:answer] ).to be_nil
          expect( find_by_qp(ret, 6)[:answer] ).to be_nil
        end
      end
    end

    context 'in funnel question when using automatic employee_connection' do
      before do
        @qq1.update!(is_funnel_question: true)
        @q.update!(use_employee_connections: true)
        EmployeesConnection.create!(employee_id: @e1.id, connection_id: @e2.id)
        EmployeesConnection.create!(employee_id: @e1.id, connection_id: @e3.id)
        EmployeesConnection.create!(employee_id: @e1.id, connection_id: @e5.id)
        add_question_reply(@qq1.id, @qp1.id, @qp2.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp3.id, false)
      end

      it 'should return correct state' do
        ret = get_question_participants('t1')[:replies]

        expect( find_by_qp(ret, 2)[:answer] ).to eq(true)
        expect( find_by_qp(ret, 3)[:answer] ).to eq(false)
        expect( find_by_qp(ret, 4) ).to be_nil
        expect( find_by_qp(ret, 5)[:answer] ).to be_nil
        expect( find_by_qp(ret, 6) ).to be_nil
      end
    end

    context 'in dependent question' do
      before do
        @qq2.update!(depends_on_question: @qq1.id)
        @qp1.update!(current_questiannair_question_id: @qq2.id)

        add_question_reply(@qq1.id, @qp1.id, @qp2.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp4.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp5.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp6.id, true)

        add_question_reply(@qq2.id, @qp1.id, @qp2.id, true)
        add_question_reply(@qq2.id, @qp1.id, @qp4.id, false)
      end

      it 'should return correct state' do
        ret = get_question_participants('t1')[:replies]

        expect( find_by_qp(ret, 2)[:answer] ).to eq(true)
        expect( find_by_qp(ret, 3) ).to be_nil
        expect( find_by_qp(ret, 4)[:answer] ).to eq(false)
        expect( find_by_qp(ret, 5)[:answer] ).to be_nil
        expect( find_by_qp(ret, 6)[:answer] ).to be_nil
      end
    end

    context 'in independent question' do
      before do
        @qp1.update!(current_questiannair_question_id: @qq2.id)
        add_question_reply(@qq2.id, @qp1.id, @qp2.id, true)
        add_question_reply(@qq2.id, @qp1.id, @qp4.id, false)
      end

      context 'without employee_connections' do
        it 'should return all employees' do
          ret = get_question_participants('t1')[:replies]

          expect( find_by_qp(ret, 2)[:answer] ).to eq(true)
          expect( find_by_qp(ret, 3)[:answer] ).to be_nil
          expect( find_by_qp(ret, 4)[:answer] ).to eq(false)
          expect( find_by_qp(ret, 5)[:answer] ).to be_nil
          expect( find_by_qp(ret, 6)[:answer] ).to be_nil
        end
      end

      context 'with employee_connections' do
        before do
          @q.update!(use_employee_connections: true)
          EmployeesConnection.create!(employee_id: @e1.id, connection_id: @e2.id)
          EmployeesConnection.create!(employee_id: @e1.id, connection_id: @e4.id)
          EmployeesConnection.create!(employee_id: @e1.id, connection_id: @e5.id)
        end

        it 'should return employees only from employees_connections' do
          ret = get_question_participants('t1')[:replies]

          expect( find_by_qp(ret, 2)[:answer] ).to eq(true)
          expect( find_by_qp(ret, 3) ).to be_nil
          expect( find_by_qp(ret, 4)[:answer] ).to eq(false)
          expect( find_by_qp(ret, 5)[:answer] ).to be_nil
          expect( find_by_qp(ret, 6) ).to be_nil
        end
      end
    end
  end

  describe 'close_questionnaire_question' do
    context 'in funnel question' do
      before do
        @qq1.update!(is_funnel_question: true)
      end

      it 'should refuse if there are no replies' do
        qd = get_questionnaire_details('t1')
        ret = close_questionnaire_question(qd)
        expect(ret).to eq 'Too few participants selected'
      end

      it 'should refuse if there are too few replies' do
        add_question_reply(@qq1.id, @qp1.id, @qp2.id, true)

        qd = get_questionnaire_details('t1')
        ret = close_questionnaire_question(qd)
        expect(ret).to eq 'Too few participants selected'
      end

      it 'should refuse if there are too many replies' do
        add_question_reply(@qq1.id, @qp1.id, @qp2.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp3.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp4.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp5.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp6.id, true)

        qd = get_questionnaire_details('t1')
        ret = close_questionnaire_question(qd)
        expect(ret).to eq 'Too many participants selected'
      end

      it 'should refuse if there are not enough "true" replies' do
        add_question_reply(@qq1.id, @qp1.id, @qp2.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp3.id, false)

        qd = get_questionnaire_details('t1')
        ret = close_questionnaire_question(qd)
        expect(ret).to eq 'Too few participants selected'
      end

      it 'should accept if there are just enough replies' do
        add_question_reply(@qq1.id, @qp1.id, @qp2.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp3.id, true)
        add_question_reply(@qq1.id, @qp1.id, @qp4.id, true)

        qd = get_questionnaire_details('t1')
        ret = close_questionnaire_question(qd)
        expect(ret).to be_nil
      end
    end
  end
end

def find_by_qp(list, qpid)
  return list.find { |l| l[:e_id] == qpid }
end

def add_question_reply(qqid, fqpid, tqpid, answer, date=nil)
  qp = QuestionReply.create!(
    questionnaire_id: @q.id,
    questionnaire_question_id: qqid,
    questionnaire_participant_id: fqpid,
    reffered_questionnaire_participant_id: tqpid,
    answer: answer
  )

  qp.update(created_at: date, updated_at: date) if !date.nil?
end
