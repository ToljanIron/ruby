require 'spec_helper'

describe ExternalDataScore, type: :model do
  before do
    @external_data_score = ExternalDataScore.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @external_data_score }

  it { is_expected.to respond_to(:snapshot_id) }
  it { is_expected.to respond_to(:external_data_metric_id) }
  it { is_expected.not_to be_valid }

  describe 'create external_data_score ' do
    it ', when not have a  external_data_metric_id not need to create' do
      external_data_score = ExternalDataScore.new(snapshot_id: 1)
      expect(external_data_score).not_to be_valid
    end
  end
end
