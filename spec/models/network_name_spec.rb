require 'spec_helper'

describe NetworkName, type: :model do
  before do
    @network_name = NetworkName.create(name: 'Example', company_id: 2)
  end
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:company_id) }

  it 'creating 2 network names with the same company_id should not be ok' do
      @network_name = NetworkName.create(name: 'Example', company_id: 3)
      network_with_same_email = @network_name.dup
      expect(network_with_same_email.save).to eq false
    end

  it 'creating 2 network names with the same company_id shouldbe ok' do
      @network_name = NetworkName.create(name: 'Example', company_id: 3)
      network_with_same_email = @network_name.dup
      network_with_same_email.company_id = 4
      expect(network_with_same_email.save).to eq true
    end
  end
