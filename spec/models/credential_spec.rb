require 'spec_helper'

describe Credential, :type => :model do
  before do
    @credential = Credential.new
  end

  subject { @credential }

  it { is_expected.to respond_to(:company_id) }

  describe 'with invalid data should be invalid' do
    it { is_expected.not_to be_valid }
  end

end
