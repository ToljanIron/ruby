require 'spec_helper'

describe OverlayEntityType, type: :model do
  before do
    @attribute_type = OverlayEntityType.new
  end

  subject { @attribute_type }

  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:overlay_entity_type) }
  it { is_expected.to respond_to(:image_url) }
  it { is_expected.to respond_to(:network_id_1) }
  it { is_expected.to respond_to(:network_id_2) }
  it { is_expected.to respond_to(:network_id_3) }

  describe 'with valid data should be valid' do
    it { is_expected.to be_valid }
  end
end
