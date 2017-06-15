require 'spec_helper'
describe QuestionnaireRawDataHelper, type: :helper do
  before do
    EventType.create!(name: 'ERROR')
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'read_csv_to_db' do
    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should import data from csv and insert to db' do
      csv_path = './spec/helpers/questionnaire_raw_data_spec.csv'
      QuestionnaireRawDataHelper.read_csv_to_db(csv_path)
      expect(QuestionnaireRawData.first.snapshot_id).to eq(1)
      expect(QuestionnaireRawData.first.network_id).to eq(2)
      expect(QuestionnaireRawData.first.company_id).to eq(4)
      expect(QuestionnaireRawData.first.from_employee_external_id).to eq(10000)
      expect(QuestionnaireRawData.first.to_employee_external_id).to eq(10001)
      expect(QuestionnaireRawData.first.date).to eq('2014-12-03 22:00:00')
      expect(QuestionnaireRawData.first.value).to eq(1)
    end
  end


end