require 'spec_helper'

describe RawMeetingsData, :type => :model do
  before do
    @rdm = RawMeetingsData.new
  end

  subject { @rdm }

  describe 'when company_id & start_time is present' do
    before do
      @rdm.company_id = 1
      @rdm.start_time = Time.zone.now
    end
    it { is_expected.to be_valid }
  end

  describe 'when start_time is not present' do
    before { @rdm.start_time = ' ' }
    it { is_expected.not_to be_valid }
  end

  describe 'when company_id is not present' do
    before { @rdm.company_id = nil }
    it { is_expected.not_to be_valid }
  end
end
