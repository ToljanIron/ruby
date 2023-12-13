require 'spec_helper'
require './spec/spec_factory'
require './app/helpers/line_processing_context.rb'
require './app/helpers/import_data_helper.rb'

include CompanyWithMetricsFactory
include ImportDataHelper

describe InteractBackofficeHelper, type: :helper do
  before do
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
    FactoryBot.reload
  end

  describe 'create_employee' do
    it 'should update the field questionnaire_id in the group and all ancestors' do
     InteractBackofficeActionsHelper.create_new_questionnaire(1)
      p = {
        'first_name' => 'f',
        'last_name' => 'l',
        'email' => 'mail@qqq.com',
        'phone' => '052-2233445',
        'group_name' => 'L3-1'
      }
      InteractBackofficeHelper.create_employee(1, p, Questionnaire.last)
      expect(Group.find_by(name: 'L3-1', snapshot_id: 2).questionnaire_id).to eq(1)
      expect(Group.find_by(name: 'L2-1', snapshot_id: 2).questionnaire_id).to eq(1)
      expect(Group.find_by(name: 'Root', snapshot_id: 2).questionnaire_id).to eq(1)
    end
  end

  describe 'update_employee' do
    it 'changing an employees group should update questionnaire_id in relevant groups' do
      InteractBackofficeActionsHelper.create_new_questionnaire(1)
      p = {
        'first_name' => 'f',
        'last_name' => 'l',
        'email' => 'mail@qqq.com',
        'phone' => '052-2233445',
        'group_name' => 'L3-1'
      }
      InteractBackofficeHelper.create_employee(1, p, Questionnaire.last)
      p['group_name'] = 'L3-3'
      p['id'] = Employee.last.id
      InteractBackofficeHelper.update_employee(1, p, Questionnaire.last.id)

      expect(Group.find_by(name: 'L3-1', snapshot_id: 2).questionnaire_id).to be_nil
      expect(Group.find_by(name: 'L2-1', snapshot_id: 2).questionnaire_id).to be_nil
      expect(Group.find_by(name: 'L3-3', snapshot_id: 2).questionnaire_id).to eq(1)
      expect(Group.find_by(name: 'L2-2', snapshot_id: 2).questionnaire_id).to eq(1)
      expect(Group.find_by(name: 'Root', snapshot_id: 2).questionnaire_id).to eq(1)
    end

  end

  describe 'validate employee' do
    it 'works' do
      InteractBackofficeActionsHelper.create_new_questionnaire(1)
      p = {
        'first_name' => 'f',
        'last_name' => 'l',
        'email' => 'mail1@qqq.com',
        'phone' => '052-2233445',
        'group_name' => 'L3-1',
        'is_verified'=>false
      }
      
      InteractBackofficeHelper.create_employee(1, p, Questionnaire.last)
      num_qps=QuestionnaireParticipant.count
      expect(Employee.last.is_verified).to eq(false)
      xls=InteractBackofficeHelper.download_employees(1,Employee.last.snapshot_id,'unverified')

      validate_unverified_by_excel_sheet(1,File.open('./tmp/'+xls), Questionnaire.last.id)
      #@attrs={company_id:1,email:'joe@test.com',first_name:'joe',last_name:'smith'}
      #csv_line=['20231211133248','joe','schmoe','joe@test.com','a','b','c','male','r','123','123','','','','','','','','',21936]
      expect(Employee.last.is_verified).to eq(true)
      expect(num_qps).to eq(QuestionnaireParticipant.count)
    end
  end
end
