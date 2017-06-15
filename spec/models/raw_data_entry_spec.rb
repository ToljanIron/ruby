require 'spec_helper'

describe RawDataEntry, :type => :model do

  before do
    @rde = RawDataEntry.new
  end

  subject { @rde }

  it { is_expected.to respond_to(:msg_id) }
  it { is_expected.to respond_to(:reply_to_msg_id) }
  it { is_expected.to respond_to(:from) }
  it { is_expected.to respond_to(:to) }
  it { is_expected.to respond_to(:cc) }
  it { is_expected.to respond_to(:bcc) }
  it { is_expected.to respond_to(:priority) }
  it { is_expected.to respond_to(:fwd) }
  it { is_expected.to respond_to(:processed) }

  describe 'when msg_id & from is present' do
    before do
      @rde.msg_id = 'id'
      @rde.from = 'from'
    end
    it { is_expected.to be_valid }
  end

  describe 'when msg_id is not present' do
    before { @rde.msg_id = ' ' }
    it { is_expected.not_to be_valid }
  end

  describe 'when from is not present' do
    before { @rde.from = ' ' }
    it { is_expected.not_to be_valid }
  end

end
