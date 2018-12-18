require 'spec_helper'

describe QuestionnaireHelper, type: :helper do

  before do
    @c = Company.create!(name: "Acme")
    @q = Questionnaire.create!(name: "test", company_id: @c.id, state: 'sent')

    @e1 = Employee.create!(company_id: @c.id, email: 'bb1@mail.com', first_name: 'Bb1', last_name: 'Qq1', external_id: 'bbb1')
    @e2 = Employee.create!(company_id: @c.id, email: 'bb2@mail.com', first_name: 'Bb2', last_name: 'Qq2', external_id: 'bbb2')
    @e3 = Employee.create!(company_id: @c.id, email: 'bb3@mail.com', first_name: 'Bb3', last_name: 'Qq3', external_id: 'bbb3')
    @e4 = Employee.create!(company_id: @c.id, email: 'bb4@mail.com', first_name: 'Bb4', last_name: 'Qq4', external_id: 'bbb4')
    @e5 = Employee.create!(company_id: @c.id, email: 'bb5@mail.com', first_name: 'Bb5', last_name: 'Qq5', external_id: 'bbb5')
    @e6 = Employee.create!(company_id: @c.id, email: 'bb6@mail.com', first_name: 'Bb6', last_name: 'Qq6', external_id: 'bbb6')

    @qp1 = QuestionnaireParticipant.create!(employee_id: @e1.id, questionnaire_id: @q.id, active: true, token: 't1')
    @qp2 = QuestionnaireParticipant.create!(employee_id: @e2.id, questionnaire_id: @q.id, active: true, token: 't2')
    @qp3 = QuestionnaireParticipant.create!(employee_id: @e3.id, questionnaire_id: @q.id, active: true, token: 't3')
    @qp4 = QuestionnaireParticipant.create!(employee_id: @e4.id, questionnaire_id: @q.id, active: true, token: 't4')
    @qp5 = QuestionnaireParticipant.create!(employee_id: @e5.id, questionnaire_id: @q.id, active: true, token: 't5')
    @qp6 = QuestionnaireParticipant.create!(employee_id: @e6.id, questionnaire_id: @q.id, active: true, token: 't6')
    @qp7 = QuestionnaireParticipant.create!(employee_id: -1, questionnaire_id: @q.id, active: true,     token: 't7', participant_type: 'tester')

    @qq1 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 11, active: true, order: 1)
    @qq2 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 12, active: true, order: 2)
    @qq3 = QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: @q.id, network_id: 13, active: true, order: 3)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'get_questionnaire_details' do
	  it 'should get all questionnaire details' do
      res = get_questionnaire_details('t2')
      expect( res[:q_state] ).to eq('sent')
      expect( res[:qp_state] ).to eq('notstarted')
      expect( res[:questionnaire_id] ).to eq(@q.id)
      expect( res[:total_questions] ).to eq(3)
    end

    it 'should raise exception if participant does not exsit' do
      expect{ get_questionnaire_details('t11') }.to raise_error(RuntimeError, 'Not found participant with token: t11')
    end
  end

  describe 'get_question_participants' do

    context 'in funnel question when not using automatic employee_connection' do
      before do
        @qq1.update!(is_funnel_question: true)
        @q.update!(use_employee_connections: false)
      end

      it 'should return all employees with answer nil' do
        ret = get_question_participants('t1')
        qps_with_answer_nil = ret.select { |r| r[:answer].nil? }
        expect( qps_with_answer_nil.length ).to eq (5)
      end

      context 'when there are already some replies' do
        before do
          add_question_reply(@qq1.id, @qp1.id, @qp2.id, true)
          add_question_reply(@qq1.id, @qp1.id, @qp3.id, false)
        end

        it 'should return some employees with answer nil and some with numbers' do
          ret = get_question_participants('t1')

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
        ret = get_question_participants('t1')

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
        ret = get_question_participants('t1')

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
          ret = get_question_participants('t1')

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
          ret = get_question_participants('t1')

          expect( find_by_qp(ret, 2)[:answer] ).to eq(true)
          expect( find_by_qp(ret, 3) ).to be_nil
          expect( find_by_qp(ret, 4)[:answer] ).to eq(false)
          expect( find_by_qp(ret, 5)[:answer] ).to be_nil
          expect( find_by_qp(ret, 6) ).to be_nil
        end
      end
    end

  end
end

def find_by_qp(list, qpid)
  return list.find { |l| l[:qpid] == qpid }
end

def add_question_reply(qqid, fqpid, tqpid, answer)
  QuestionReply.create!(
    questionnaire_id: @q.id,
    questionnaire_question_id: qqid,
    questionnaire_participant_id: fqpid,
    reffered_questionnaire_participant_id: tqpid,
    answer: answer
  )
end
