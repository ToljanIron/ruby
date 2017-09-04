require 'spec_helper'

describe Company, type: :model do

  before do
    @company = Company.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @company }

  describe 'last_snapshot' do
    it 'should return last snapshot by timestamp' do
      @company[:name] = '1'
      @company.save
      [0, 100, 200].each { |s| FactoryGirl.create(:snapshot, timestamp: Time.now + s) }
      expect(@company.last_snapshot.id).to eq(3)
    end
  end

  describe ', with valid data should be valid' do
    it 'valid name' do
      subject[:name] = 'some name'
      is_expected.to be_valid
    end
  end

  it ', list_offices should return list of offices names' do
    c = Company.find_or_create_by(name: 'aaa')
    FactoryGirl.create_list(:office, 10)
    res = c.list_offices
    expect(res.count).to eq(10)
  end

  describe 'emails' do
    before do
      @company = Company.create(id: 1, name: 'test_class')
      FactoryGirl.create_list(:employee, 3, company_id: @company.id)

      EmployeeAliasEmail.create(email_alias: 'ali1@g.com', employee_id: 3)
      EmployeeAliasEmail.create(email_alias: 'ali22@g.com', employee_id: 3)
      EmployeeAliasEmail.create(email_alias: 'ali43@g.com', employee_id: 3)

      EmployeeAliasEmail.create(email_alias: 'mor23@g.com', employee_id: 2)
      EmployeeAliasEmail.create(email_alias: 'mor54@g.com', employee_id: 2)
      EmployeeAliasEmail.create(email_alias: 'mor12@g.com', employee_id: 2)

      EmployeeAliasEmail.create(email_alias: 'red78@g.com', employee_id: 1)
      EmployeeAliasEmail.create(email_alias: 'red77@g.com', employee_id: 1)
      EmployeeAliasEmail.create(email_alias: 'red@55g.com', employee_id: 1)
    end
    it 'should return an array of 12 email addresses' do
      expect(@company.emails.length).to eq(12)
    end
  end

  describe 'recovery email collection' do
    before do
      @company = Company.create(name: 'test_class')
      ApiClientTaskDefinition.create(
        name: 'exchange email collector',
        script_path: 'exchange/collect_emails_from_date_to_date.rb'
      )
      ApiClientTaskDefinition.create(
        name: 'sender',
        script_path: 'sender/sender.rb'
      )
      ApiClient.create(
        client_name: 'test_class',
        token: 'd65028a43e33af193de01e796d576e1b7e6cac318b15151ea7bba3b84ab6',
        expires_on: Time.now + 1.year
      )
    end
  end
end

def getseq
  puts Employee.connection.select_value("select nextval('public.employees_id_seq')").to_i
end
