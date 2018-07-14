require 'spec_helper'
require './spec/spec_factory'
include CompanyWithMetricsFactory

describe InteractBackofficeHelper, type: :helper do
  before do
    puts "&&&&&&&&&&&&&&&&&&&"
    puts "In before do"
    ap Group.select(:name, :snapshot_id, :questionnaire_id).order(:id)
    puts "&&&&&&&&&&&&&&&&&&&"
    Company.find_or_create_by(id: 1, name: "Hevra10")
    Snapshot.find_or_create_by(name: "2016-01", company_id: 1, timestamp: 3.weeks.ago)
    g0 = Group.find_or_create_by(name: "Root", company_id: 1, color_id: 10, external_id: '123' )
    g1 = Group.find_or_create_by(name: "L2-1", company_id: 1, parent_group_id: g0.id, color_id: 10, external_id: '124')
    g2 = Group.find_or_create_by(name: "L2-2", company_id: 1, parent_group_id: g0.id, color_id: 10, external_id: '125')
    Group.find_or_create_by(name: "L3-1", company_id: 1, parent_group_id: g1.id, color_id: 10, external_id: '126')
    Group.find_or_create_by(name: "L3-2", company_id: 1, parent_group_id: g1.id, color_id: 10, external_id: '127')
    Group.find_or_create_by(name: "L3-3", company_id: 1, parent_group_id: g2.id, color_id: 10, external_id: '128')
    create_emps('moshe', 'acme.com', 5, {gid: 6})
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'create_employee' do
    it 'should update the field questionnaire_id in the group and all ancestors' do
      ap Group.select(:name, :snapshot_id, :questionnaire_id).order(:id)
      puts "------------------------"
      InteractBackofficeActionsHelper.create_new_questionnaire(1)
      ap Group.select(:name, :snapshot_id, :questionnaire_id).order(:id)
      puts "------------------------"
      aq = Questionnaire.last
      p = {
        'first_name' => 'f',
        'last_name' => 'l',
        'email' => 'mail@qqq.com',
        'phone' => '052-2233445',
        'group' => 'L3-1'
      }
      InteractBackofficeHelper.create_employee(1, p, aq)
      ap Group.select(:name, :snapshot_id, :questionnaire_id).order(:id)
      puts "------------------------"
      #ap Group.where(name: 'L3-1', snapshot_id: 2)
      #ap Group.where(name: 'L2-1', snapshot_id: 2)
      #ap Group.where(name: 'Root', snapshot_id: 2)
    end
  end

  describe 'QQQQQQQQQQQQQQQQQQ' do
    qid = -1
    before do
      InteractBackofficeActionsHelper.create_new_questionnaire(1)
      qid = Questionnaire.last.id
      (0..3).each do |i|
        QuestionnaireParticipant.create!(employee_id: i+1, questionnaire_id: qid, active: true)
        QuestionnaireQuestion.create!(company_id: 1, questionnaire_id: qid, network_id: i, order: i, active: true, title: "title-#{i}")
      end
    end

  end
end
