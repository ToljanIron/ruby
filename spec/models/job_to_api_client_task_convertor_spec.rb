require 'spec_helper'
include ConvertionAlgorithmsHelper

describe JobToApiClientTaskConvertor, type: :model do
  before do
    @convertor = JobToApiClientTaskConvertor.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @convertor }

  it { is_expected.to respond_to(:job_id) }
  it { is_expected.to respond_to(:algorithm_name) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.not_to be_valid }

  describe 'create_covertor' do
    before do
      job_id = 1
      algo_name = 'alog'
      @convertor = JobToApiClientTaskConvertor.create_covertor(job_id, algo_name)
    end

    it { is_expected.to be_valid }
  end

  describe 'covert' do
    it 'should call run algorithm_name when is algorithm_name valid' do
      res = nil
      subject[:algorithm_name] = 'demo_algo'
      args = { arg1: 1, arg2: 2 }
      expect(ConvertionAlgorithmsHelper).to receive(:demo_algo).with(anything) { res = args }
      subject.convert(args)
      expect(res).to be args
    end
    it 'when algorithm_name is invalid' do
      expect { subject.convert }.to raise_error
    end
  end
end
