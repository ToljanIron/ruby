require 'spec_helper'
require './spec/spec_factory'
include CompanyWithMetricsFactory
include InteractBackofficeActionsHelper

describe 'Questionnaire processes' do
  cid = -1
  sid = -1
  rootgid = -1

  before do
    cid = Company.create!(name: "Hevra10").id
    sid = Snapshot.create!(name: "2016-01", company_id: 1, timestamp: 5.weeks.ago).id
    Algorithm.create!(id: 601, name: 'interact_indegree', algorithm_type_id: 8)
    FactoryGirl.create(:question, is_funnel_question: true)
    FactoryGirl.create(:question)
    FactoryGirl.create(:question)
    rootgid = FactoryGirl.create(:group, name: 'Comp').id
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'Existing groups and employees' do
    it 'should be copied over' do
      l21gid = FactoryGirl.create(:group, name: 'L2-1', parent_group_id: rootgid).id
      create_emps('moshe', 'hevra10.com', 2, {gid: l21gid})
      InteractBackofficeActionsHelper.create_new_questionnaire(cid)
      lastsid = Snapshot.last
      groups = Group.by_snapshot(lastsid)
      expect( groups.count ).to eq(2)
      emps = Employee.by_snapshot(lastsid)
      expect( emps.count ).to eq(2)
    end
  end

  describe 'Ceate new questinnaire' do
    before do
      InteractBackofficeActionsHelper.create_new_questionnaire(cid)
    end

    it 'should create a new snashot' do
      expect(Snapshot.count).to eq(2)
    end

    it 'There should be some inactive questions' do
      qqs = QuestionnaireQuestion.all.pluck(:active)
      expect( qqs.count ).to eq(3)
      expect( qqs.reduce(false) {|s,n| s || n} ).to be_falsy
    end

    it 'There should be exactly one test questionnaire participant' do
      qps = QuestionnaireParticipant.all
      expect( qps.length ).to eq(1)
      expect( qps[0].employee_id ).to eq(-1)
    end

    it 'The state should be created' do
      q = Questionnaire.first
      expect( q.state ).to eq('created')
    end
  end

  describe 'Adding a new question' do
    qid = nil
    questnum = nil

    before do
      InteractBackofficeActionsHelper.create_new_questionnaire(cid)
      questnum = QuestionnaireQuestion.count
      qid = Questionnaire.last.id
      question = {'title' => 'New title', 'body' => 'New body',
                  'min' => 3, 'max' => 5, 'active' => true }
      InteractBackofficeHelper.create_new_question(cid, qid, question, 3)
    end

    it 'There should be one new question' do
      expect( QuestionnaireQuestion.count ).to eq(questnum + 1)
    end

    it 'number of networks should be same as questions' do
      expect( QuestionnaireQuestion.count ).to eq(NetworkName.where(questionnaire_id: qid).count)
    end
  end

  describe 'Questionnaire participant' do
    aq = nil
    par = nil
    participnatsnum = nil
    groupsnum = nil

    before do
      InteractBackofficeActionsHelper.create_new_questionnaire(cid)
      aq = Questionnaire.last
      participnatsnum = QuestionnaireParticipant.count
      groupsnum = Group.count
      par = {'first_name' => 'Oren', 'last_name' => 'Cohen', 'email' => 'or@mail0900098098.co.zz',
             'phone' => '099-9998822', 'group' => 'Comp', 'office' => 'Off1',
             'role' => 'Role1', 'ranke': 12, 'job_title' => 'JT1', 'gender' => 0 }
    end

    describe 'Add new participant' do
      it 'with existing group' do
        InteractBackofficeHelper.create_employee(cid, par, aq)
        expect(QuestionnaireParticipant.count).to eq(participnatsnum + 1)
        emp = Employee.last
        expect( emp.first_name ).to eq('Oren')
        expect( Group.count ).to eq(groupsnum)
        expect( Group.last.questionnaire_id ).to eq(aq.id)
      end

      it 'with new group' do
        par['group'] = 'NewGrp'
        InteractBackofficeHelper.create_employee(cid, par, aq)
        expect( Group.count ).to eq(groupsnum + 1)
        expect( Group.last.questionnaire_id ).to eq(aq.id)
        expect( Group.last.name ).to eq('NewGrp')
      end

      it 'New employee with new role' do
        InteractBackofficeHelper.create_employee(cid, par, aq)
        expect( Role.where(name: 'Role1').count ).to eq(1)
      end
    end

    describe 'Delete an existing one' do
      qpid = nil

      before do
        InteractBackofficeHelper.create_employee(cid, par, aq)
        qpid = QuestionnaireParticipant.last.id
        QuestionReply.create!(
          questionnaire_id: aq.id,
          questionnaire_question_id: 999,
          questionnaire_participant_id: qpid,
          reffered_questionnaire_participant_id: 999,
          answer: true
        )
      end

      it 'particpant and his answers should be removed from tables' do
        InteractBackofficeHelper.delete_employee(qpid)
        expect( QuestionnaireParticipant.where('employee_id <> -1').count ).to eq(0)
        expect( QuestionReply.count ).to eq(0)
      end

      it 'State of questionnaire should be consistant' do
        InteractBackofficeHelper.delete_employee(qpid)
        aq = Questionnaire.last
        expect( aq.state ).to eq('notstarted')
      end
    end

    describe 'Upate participant' do
      it 'change its group' do
        InteractBackofficeHelper.create_employee(cid, par, aq)
        eid = Employee.last.id
        par['eid'] = eid
        par['group'] = 'NewGrp'
        InteractBackofficeHelper.update_employee(cid, par, aq.id)
        expect( Group.count ).to eq(groupsnum + 1)
        expect( Group.last.name ).to eq('NewGrp')
      end
    end
  end

  describe 'Duplicate a questionnaire' do
    aq = nil
    par = nil
    participnatsnum = nil
    groupsnum = nil
    snapshotnum = nil

    before do
      InteractBackofficeActionsHelper.create_new_questionnaire(cid)
      aq = Questionnaire.last
      participnatsnum = QuestionnaireParticipant.count
      groupsnum = Group.count
      par = {'first_name' => 'Oren', 'last_name' => 'Cohen', 'email' => 'or@mail0900098098.co.zz',
             'phone' => '099-9998822', 'group' => 'Comp', 'office' => 'Off1',
             'role' => 'Role1', 'ranke': 12, 'job_title' => 'JT1', 'gender' => 0 }
      InteractBackofficeHelper.create_employee(cid, par, aq)
      snapshotnum = Snapshot.count
    end

    it 'should create duplicate satalite entities' do
      InteractBackofficeActionsHelper.create_new_questionnaire(cid, aq.id)
      newaq = Questionnaire.last

      expect( Questionnaire.count ).to eq(2)
      expect( Questionnaire.last.name[-4..-1] ).to eq('copy')
      expect( Questionnaire.first.sms_text ).to eq( Questionnaire.last.sms_text )

      expect( Snapshot.count ).to eq(   snapshotnum + 1 )
      sid = Snapshot.last.id
      expect( newaq.snapshot_id ).to eq(sid)
      expect( Employee.by_snapshot(sid).count ).to eq(1)
      expect( Group.by_snapshot(sid).count ).to eq(1)

      expect( QuestionnaireParticipant.where(questionnaire_id: newaq.id).count ).to eq(2)
      expect( QuestionnaireQuestion.where(questionnaire_id: newaq.id).count ).to eq(3)
      expect( QuestionReply.where(questionnaire_id: newaq.id).count ).to eq(0)

      expect(QuestionnaireParticipant.last.status ).to eq('notstarted')
    end

    it 'should have state :created' do
      aq.update!(state: :completed)
      InteractBackofficeActionsHelper.create_new_questionnaire(cid, aq.id)
      newaq = Questionnaire.last
      expect( newaq.state ).to eq('created')
      expect( newaq.prev_questionnaire_id ).to be_nil
    end

    it 'as a followup should populate prev_questionnaire_id' do
      InteractBackofficeActionsHelper.create_new_questionnaire(cid, aq.id, true)
      newaq = Questionnaire.last
      expect( newaq.prev_questionnaire_id ).to eq(aq.id)
    end
  end

end
