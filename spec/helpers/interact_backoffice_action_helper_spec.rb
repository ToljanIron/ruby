require 'spec_helper'
require './spec/spec_factory'
include CompanyWithMetricsFactory

describe InteractBackofficeActionsHelper, type: :helper do
  before do
    Company.find_or_create_by(id: 1, name: "Hevra10")
    Snapshot.find_or_create_by(name: "2016-01", company_id: 1, timestamp: 3.weeks.ago)
    Group.find_or_create_by(name: "Root", company_id: 1, color_id: 10, external_id: '123' )
    Group.find_or_create_by(name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10, external_id: '124')
    NetworkName.find_or_create_by!(name: "Communication Flow", company_id: 1)
    create_emps('moshe', 'acme.com', 5, {gid: 6})
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'Copy questionnaire' do
    it 'should create a new questionnaire with a new snapshot' do
      InteractBackofficeActionsHelper.create_new_questionnaire(1)
      expect(Questionnaire.count).to eq(1)
      expect(Questionnaire.last.snapshot_id).to be > 1
      expect(Snapshot.count).to eq(2)
      expect(Group.count).to eq(4)
      expect(Employee.count).to eq(10)
    end
  end

  describe 'Rerun a questionnaire' do
    qid = -1
    before do
      InteractBackofficeActionsHelper.create_new_questionnaire(1)
      qid = Questionnaire.last.id
      (0..3).each do |i|
        QuestionnaireParticipant.create!(employee_id: i+1, questionnaire_id: qid, active: true)
        QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: qid, network_id: i, order: i, active: true, title: "title-#{i}")
      end
    end

    it 'should create a copy of the questionnaire, and a new snapshot' do
      InteractBackofficeActionsHelper.create_new_questionnaire(1, qid)
      expect(Questionnaire.count).to eq(2)
      expect(Questionnaire.last.snapshot_id).to be > qid
      expect(Questionnaire.last.prev_questionnaire_id).to eq(qid)
      expect(Snapshot.count).to eq(3)
      expect(Group.count).to eq(6)
      expect(Employee.count).to eq(15)
      expect(QuestionnaireParticipant.count).to eq(10)
      expect(QuestionnaireParticipant.where.not(employee_id: -1).count).to eq(8)
      expect(QuestionnaireQuestion.count).to eq(8)
      expect(QuestionnaireQuestion.last.active).to be_truthy
    end

    it 'should have corrent questionnaire_id value' do
      sid = Questionnaire.last.snapshot_id
      qid = Questionnaire.last.id
      Group.where(snapshot_id: sid).last.update!(questionnaire_id: qid)
      InteractBackofficeActionsHelper.create_new_questionnaire(1, qid)
      expect(Group.last.questionnaire_id).to eq(Questionnaire.last.id)
    end
  end
end
