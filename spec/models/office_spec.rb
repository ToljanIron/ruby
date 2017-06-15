require 'spec_helper'

describe Office, type: :model do

  before do
    @office = Office.new
  end

  subject { @office }

  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:company_id) }

  describe 'with invalid data should be invalid' do
    it { is_expected.not_to be_valid }
  end

  describe ', with valid data should be valid' do
    it do
      subject[:name] = 'some name'
      subject[:company_id] = 1
      is_expected.to be_valid
    end
  end
end
