require 'spec_helper'
require './spec/spec_factory'

#describe ExcelHelper, type: :helper, write_file: true do
describe 'ExcelHelper' do
  before do
    Company.create!(id: 1, name: "Hevra10")
    NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
    Algorithm.create!(id: 700, name: 'algo_1')
    Algorithm.create!(id: 702, name: 'algo_2')
    MetricName.create!(id: 1, name: 'Algo1', company_id: 1)
    MetricName.create!(id: 2, name: 'Algo2', company_id: 1)
    Office.create!(id: 1, name: 'Office1', company_id: 1)
    CompanyMetric.create!(id: 1, algorithm_id: 700, metric_id: 1, algorithm_type_id: 1, network_id:123, company_id: 1)
    CompanyMetric.create!(id: 2, algorithm_id: 702, metric_id: 2, algorithm_type_id: 1, network_id:123, company_id: 1)

    ## Snapshot
    Snapshot.create!(id: 1, name: "S1", company_id: 1, timestamp: '2017-10-20')
    Group.create!(id: 6, name: "R&D", company_id: 1, snapshot_id: 1, external_id: 'ext6')
    Group.create!(id: 8, name: "IT",  company_id: 1, snapshot_id: 1, external_id: 'ext8')
    create_emps('moshe', 'acme.com', 5, {gid: 6})
    FactoryGirl.create(:cds_metric_score, employee_id: 1, score: 1.1, algorithm_id: 700, group_id: 6, snapshot_id: 1, company_metric_id: 1)
    FactoryGirl.create(:cds_metric_score, employee_id: 2, score: 1.2, algorithm_id: 700, group_id: 6, snapshot_id: 1, company_metric_id: 1)
    FactoryGirl.create(:cds_metric_score, employee_id: 3, score: 1.3, algorithm_id: 700, group_id: 6, snapshot_id: 1, company_metric_id: 1)
    FactoryGirl.create(:cds_metric_score, employee_id: 1, score: 2.1, algorithm_id: 702, group_id: 6, snapshot_id: 1, company_metric_id: 2)
    FactoryGirl.create(:cds_metric_score, employee_id: 2, score: 2.2, algorithm_id: 702, group_id: 6, snapshot_id: 1, company_metric_id: 2)
    FactoryGirl.create(:cds_metric_score, employee_id: 3, score: 2.3, algorithm_id: 702, group_id: 6, snapshot_id: 1, company_metric_id: 2)
  end

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  it 'the report should not throw an error' do
    file_name = nil
    expect { file_name = ExcelHelper::create_xls_report_for_emails( 1, [6], 'Oct/17', 'By Month', [700,702])}.not_to raise_error
    # move_file_to_shared_folder(file_name)
    remove_file(file_name)
  end

  describe 'get_group_data' do
    it 'should create 2 entries for the populated snapshot and to be well formatted' do
      res = ExcelHelper::get_group_data(1, [6], 'Oct/17', 'By Month', [700, 702])
      expect(res.length).to eq(2)
      expect(res[0].key?('group_name')).to be_truthy
      expect(res[0].key?('group_extid')).to be_truthy
      expect(res[0].key?('algorithm_name')).to be_truthy
      expect(res[0].key?('sum')).to be_truthy
    end
  end

  describe 'get_employees_data' do
    it 'should create 3 entries for the populated snapshot and to be well formatted' do
      res = ExcelHelper::get_employees_data(1, 'Oct/17', 'By Month', [700, 702])
      expect(res.length).to eq(6)
      expect(res[0].key?(:group_name)).to be_truthy
      expect(res[0].key?(:name)).to be_truthy
      expect(res[0].key?(:algorithm_name)).to be_truthy
      expect(res[0].key?(:score)).to be_truthy
      expect(res[0].key?(:interval)).to be_truthy
      expect(res[0].key?(:email)).to be_truthy
      expect(res[0].key?(:external_id)).to be_truthy
    end
  end

  describe 'encryption' do
    it 'should be encypted without throwing errors' do
      file_name = nil
      expect { file_name = ExcelHelper::create_xls_report_for_emails( 1, [6], 'Oct/17', 'By Month', [700,702], 'qwer')}.not_to raise_error
      move_file_to_shared_folder(file_name)
    end
  end

  def move_file_to_shared_folder(file_name)
    `mv #{file_name} ~/host`
  end

  def remove_file(file_name)
    `rm #{file_name}`
  end
end

