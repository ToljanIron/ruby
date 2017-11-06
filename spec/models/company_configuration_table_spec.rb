require 'spec_helper'

describe CompanyConfigurationTable, type: :model do
  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'get_company_locale' do
    before(:each) do
      CompanyConfigurationTable.create(key: CompanyConfigurationTable::LOCALE, value: 'he', comp_id: 22)
    end

    it 'should return he for company 22' do
      expect( CompanyConfigurationTable::get_company_locale(22) ).to eq('he')
    end

    it 'should return en for non existant company' do
      expect( CompanyConfigurationTable::get_company_locale(23) ).to eq('en')
    end

    it 'should return en for no compay at all' do
      expect( CompanyConfigurationTable::get_company_locale ).to eq('en')
    end
  end

  describe 'should_display_emails?' do
    it 'should return true if value is the string true' do
      CompanyConfigurationTable.create(key: CompanyConfigurationTable::DISPLAY_EMAILS, value: 'true', comp_id: -1)
      expect( CompanyConfigurationTable::should_display_emails? ).to be_truthy
    end

    it 'should return false if value is false' do
      CompanyConfigurationTable.create(key: CompanyConfigurationTable::DISPLAY_EMAILS, value: 'false', comp_id: -1)
      expect( CompanyConfigurationTable::should_display_emails? ).to be_falsy
    end

    it 'should return false if there is no entry in the db' do
      expect( CompanyConfigurationTable::should_display_emails? ).to be_falsy
    end

    it 'should return false if value is anything but the string true' do
      CompanyConfigurationTable.create(key: CompanyConfigurationTable::DISPLAY_EMAILS, value: "a", comp_id: -1)
      expect( CompanyConfigurationTable::should_display_emails? ).to be_falsy
      CompanyConfigurationTable.create(key: CompanyConfigurationTable::DISPLAY_EMAILS, value: 100, comp_id: -1)
      expect( CompanyConfigurationTable::should_display_emails? ).to be_falsy
    end
  end

  describe 'display_field_in_questionnaire'do
    it 'shoud return "role"' do
      CompanyConfigurationTable.create(key: CompanyConfigurationTable::DISPLAY_FIELD_IN_QUESTIONNAIRE, value: 'role', comp_id: -1)
      expect( CompanyConfigurationTable.display_field_in_questionnaire ).to eq('role')
    end

    it 'should return "job_title"' do
      CompanyConfigurationTable.create(key: CompanyConfigurationTable::DISPLAY_FIELD_IN_QUESTIONNAIRE, value: 'job_title', comp_id: -1)
      expect( CompanyConfigurationTable.display_field_in_questionnaire ).to eq('job_title')
    end

    it 'should return "role" by default' do
      expect( CompanyConfigurationTable.display_field_in_questionnaire ).to eq('role')
    end

    it 'should throw and exception if illeagl value in key' do
      CompanyConfigurationTable.create(key: CompanyConfigurationTable::DISPLAY_FIELD_IN_QUESTIONNAIRE, value: 'qqq', comp_id: -1)
      expect { CompanyConfigurationTable.display_field_in_questionnaire }.to raise_error(RuntimeError)
      #expect { CompanyConfigurationTable.display_field_in_questionnaire }.to raise_error('Value: qq is not permitted for key: display_field_in_questionnaire')
    end
  end
end
