require 'spec_helper'

describe Pin, type:  :model do
  before do
    definition = '{"conditions": [{"param": "rank", "vals": [2]}, {"param": "title", "vals": [3, 1]}], "employees": ["a@email.com"]}'
    ui_definition = '{"conditions": [{"param": "rank", "vals": [2]}, {"param": "title", "vals": [3, 1]}], "employees": ["a@email.com"]}'
    @pin = Pin.new(company_id: 1, name: 'testpin', definition: definition, ui_definition: ui_definition)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe ', check definition serealization to database' do
    it 'should return valid object' do
      res = @pin.pack_to_json
      d = res[:definition]
      expect(d['conditions'][0]['param']).to eq('rank')
    end
  end

  describe ', verify that given a pin the employees can be queried' do
    before do
      FactoryGirl.create_list(:employee, 4)
      FactoryGirl.create_list(:pin, 2)
      EmployeesPin.create(pin_id: 1, employee_id: 1)
      EmployeesPin.create(pin_id: 1, employee_id: 2)
      EmployeesPin.create(pin_id: 1, employee_id: 3)
    end

    it ' should return a valid list of employees' do
      pin = Pin.find(1)
      emps = pin.employees
      expect(emps.length).to eq(3)
    end
  end
end
