require 'spec_helper'

describe ExternalDataMetric, type: :model do
  before do
    @external_data_metric = ExternalDataMetric.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @external_data_metric }

  it { is_expected.to respond_to(:external_metric_name) }
  it { is_expected.to respond_to(:company_id) }
  it { is_expected.not_to be_valid }

  describe 'create external_data_metric ' do
    it ', when not have a external_metric_name not need to create' do
      external_data_metric = ExternalDataMetric.new
      expect(external_data_metric).not_to be_valid
    end
  end
end
