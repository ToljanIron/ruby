require 'spec_helper'

describe EmployeeAliasEmail, :type => :model do

  before do
    @alias = EmployeeAliasEmail.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @alias }

  it { is_expected.to respond_to(:email_alias) }
  it { is_expected.to respond_to(:employee_id) }

  describe 'find_employee_by_alias' do
    it ', when employee has alias' do
      email_alias = 'alias@email.com'
      emp = FactoryGirl.create(:employee)
      EmployeeAliasEmail.create(email_alias: email_alias, employee_id: emp.id)

      alias_email = Employee.aliases(emp.id)
      expect(alias_email[0].employee_id).to eq(emp.id)
    end

    it ", when employee doesn't have alias" do
      emp = FactoryGirl.create(:employee)
      alias_email = Employee.aliases(emp.id)
      expect(alias_email.all.length).to eq(0)
    end
  end
end
