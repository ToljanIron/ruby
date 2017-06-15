require 'spec_helper'
require 'rake'

describe 'create_and_calculate_presets job' do
  subject { Rake::Task['db:create_and_calculate_presets'] }

  before do
    Rake::Task['db:seed:event_types'].reenable
    Rake::Task['db:seed:event_types'].invoke
    subject.reenable
  end

  describe 'test scenario' do
    before do
      Company.create(id: 1, name: "Comp1")
      conditions1 = '{"conditions": [{"param": "rank_id", "vals": [1]}], "employees": ["employee2@email.com"]}'
      conditions2 = '{"conditions": [], "employees": ["employee3@email.com"], "groups": [4]}'
      FactoryGirl.create(:pin, definition: conditions1, ui_definition: conditions1, status: :pre_create_pin)
      FactoryGirl.create(:pin, name: 'pin2', definition: conditions2, ui_definition: conditions2, status: :saved)
      FactoryGirl.create(:metric, name: 'Collaboration', metric_type: 'measure', index: 1)
      Snapshot.create(name: 's1', company_id: 1, snapshot_type: 1, timestamp: '22-12-2014')
      MetricScore.create(company_id: 1, employee_id: 1, snapshot_id: 1, metric_id: 1, score: 1.10)
      MetricScore.create(company_id: 1, employee_id: 2, snapshot_id: 1, metric_id: 1, score: 2.10)
      FactoryGirl.create(:employee, rank_id: 1)
      FactoryGirl.create(:employee, rank_id: 2, email: 'employee2@email.com')
      FactoryGirl.create(:employee, rank_id: 1, email: 'employee3@email.com')
      FactoryGirl.create(:employee, rank_id: 2)
      FactoryGirl.create(:employee, group_id: 4)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    describe 'create_and_calculate_presets with some condition in company 1' do
      it 'preset "pin1" should create and change status to "saved" and preset "pin2" should not create ar seconed time' do
        updated_at_preset_2 = Pin.find_by_name('pin2').updated_at
        subject.invoke(1)
        expect(updated_at_preset_2).to eq(Pin.find_by_name('pin2').updated_at)
        expect(Pin.find_by_name('pin1').status).to eq('saved')
      end
    end
  end
end
