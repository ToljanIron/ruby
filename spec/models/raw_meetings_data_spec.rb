require 'spec_helper'

describe RawMeetingsData, :type => :model do
  before do
    @rdm = RawMeetingsData.new
  end

  subject { @rdm }

  it { is_expected.to respond_to(:subject) }
  it { is_expected.to respond_to(:attendees) }
  it { is_expected.to respond_to(:duration_in_minutes) }
  it { is_expected.to respond_to(:external_meeting_id) }
  it { is_expected.to respond_to(:company_id) }
  it { is_expected.to respond_to(:start_time) }
  it { is_expected.to respond_to(:location) } 
  it { is_expected.to respond_to(:processed) }

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
