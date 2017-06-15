require 'spec_helper'
require 'rake'

describe 'pre_calculate_pins job' do
  subject { Rake::Task['db:pre_calculate_pins'] }

  before do
    Rake::Task['db:seed:event_types'].reenable
    Rake::Task['db:seed:event_types'].invoke
    subject.reenable
  end

  describe 'test scenario' do
    before do
      conditions1 = '{"conditions": [{"param": "rank_id", "vals": [1]}], "employees": ["employee2@email.com"]}'
      conditions2 = '{"conditions": [], "employees": ["employee3@email.com"], "groups": [4]}'
      conditions3 = '{"conditions": [], "employees": [], "groups": [4]}'
      FactoryGirl.create(:pin, definition: conditions1, ui_definition: conditions1)
      FactoryGirl.create(:pin, name: 'pin2', definition: conditions2, ui_definition: conditions2)
      FactoryGirl.create(:pin, name: 'pin3', definition: conditions2, ui_definition: conditions2, active: false)
      FactoryGirl.create(:pin, name: 'pin4', definition: conditions1, ui_definition: conditions1, status: :draft)
      FactoryGirl.create(:pin, name: 'pin5', definition: conditions3, ui_definition: conditions3)
      FactoryGirl.create(:employee, rank_id: 1)
      FactoryGirl.create(:employee, rank_id: 2, email: 'employee2@email.com')
      FactoryGirl.create(:employee, rank_id: 1, email: 'employee3@email.com')
      FactoryGirl.create(:employee, rank_id: 2)
      FactoryGirl.create(:employee, group_id: 4)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    describe 'pre_calculate_pin with some condition in company 1' do
      it 'Pin number 1 should include 3 employees, pin number 2 should include 2 employee' do
        subject.invoke(1)
        ep = EmployeesPin.where('pin_id = 1')
        emps2 = EmployeesPin.where('pin_id = 2')
        expect(ep.length).to eq(3)
        expect(emps2.length).to eq(2)
        expect(EmployeesPin.where('pin_id = 3').length).to eq(0)
      end
      it 'should not change the status of pin when the status is not pre_create_pin or saved' do
        subject.invoke(1)
        expect(Pin.where(name: 'pin4').first.status).to eq('draft')
      end
      it 'should return only 2 employees in group 4' do
        FactoryGirl.create(:employee, group_id: 4, email: 'employee6@email.com')
        subject.invoke(1)
        emps5 = EmployeesPin.where('pin_id = 5')
        expect(emps5.length).to eq(2)
      end
    end
  end
end
