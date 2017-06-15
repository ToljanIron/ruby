require 'spec_helper'

describe ApiClientTaskDefinition, type: :model do
  before do
    @task = ApiClientTaskDefinition.new
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @task }

  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:script_path) }
  it { is_expected.not_to be_valid }

  describe 'create_scheduled_task' do
    describe 'with invalid data' do
      it 'when  is invalid jobs_queue' do
        invalid_ex_1 = ApiClientTaskDefinition.create_by_name_and_script_path(nil, nil)
        invalid_ex_2 = ApiClientTaskDefinition.create_by_name_and_script_path('name', nil)
        invalid_ex_3 = ApiClientTaskDefinition.create_by_name_and_script_path(nil, 'path')
        expect(invalid_ex_1).to be nil
        expect(invalid_ex_2).to be nil
        expect(invalid_ex_3).to be nil
      end
    end

    describe 'with valid data' do
      it 'when only name is given' do
        res = ApiClientTaskDefinition.create_by_name_and_script_path('name', 'path')
        expect(res).to be_valid
      end
      it 'when only name and script_path are given' do
        res = ApiClientTaskDefinition.create_by_name_and_script_path('name', 'script/path.file')
        expect(res).to be_valid
      end
    end
  end
end
