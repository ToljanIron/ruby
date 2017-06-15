require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/update_employees_information_helper.rb'
describe UpdateEmployeesInformationHelper do
  describe 'update employee age_group and senirioty' do
    before do
      @cmp1 = Company.create(name: 'A')
      em0 = 'p0@email.com'
      em1 = 'p1@email.com'
      @e0 = FactoryGirl.create(:employee, email:  em0, company_id:  @cmp1.id, date_of_birth: 30.years.ago, work_start_date: 3.years.ago)
      @e1 = FactoryGirl.create(:employee, email:  em1, company_id:  @cmp1.id, date_of_birth: 20.years.ago, work_start_date: 5.month.ago)
      FactoryGirl.create(:age_group, name: '25-34')
      FactoryGirl.create(:age_group, name: '15-24')
      FactoryGirl.create(:seniority, name: '0')
      FactoryGirl.create(:seniority, name: '2Y')
    end
    after do
      DatabaseCleaner.clean_with(:truncation)
    end
    it 'should update the age_group of e0 to 25-34' do
      update_employee(@cmp1.id)
      expect(Employee.find(@e0.id).age_group.name).to eq('25-34')
    end
  end
end
