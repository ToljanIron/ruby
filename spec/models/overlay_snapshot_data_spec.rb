require 'spec_helper'

describe OverlaySnapshotData, type: :model do
  before do
    @attribute_snapshot_data = OverlaySnapshotData.new
  end

  subject { @attribute_snapshot_data }

  it { is_expected.to respond_to(:snapshot_id) }
  it { is_expected.to respond_to(:from_type) }
  it { is_expected.to respond_to(:from_id) }
  it { is_expected.to respond_to(:to_id) }
  it { is_expected.to respond_to(:to_type) }
  it { is_expected.to respond_to(:value) }

  describe 'with valid data should be valid' do
    it { is_expected.to be_valid }
  end
end
