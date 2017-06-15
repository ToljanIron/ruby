require 'spec_helper'

describe Reoccurrence, type: :model do
  before do
    @reoccurrence = Reoccurrence.new
  end

  subject { @reoccurrence }

  it { is_expected.to respond_to(:run_every_by_minutes) }
  it { is_expected.to respond_to(:fail_after_by_minutes) }

  describe 'with invalid data should be invalid' do
    it { is_expected.not_to be_valid }
  end

  describe ', model utils functions' do
    it ', should create reoccurrence for monthly' do
      r = Reoccurrence.create_new_occurrence(Reoccurrence.monthly, Reoccurrence.monthly)
      expect(r.run_every_by_minutes).to be == Reoccurrence::MONTH_MINUTES
    end

    it ', should create reoccurrence for weekly' do
      r = Reoccurrence.create_new_occurrence(Reoccurrence.weekly, Reoccurrence.weekly)
      expect(r.fail_after_by_minutes).to be == Reoccurrence::WEEK_MINUTES
    end

    it ', should create reoccurrence for daily' do
      r = Reoccurrence.create_new_occurrence(Reoccurrence.daily, Reoccurrence.daily)
      expect(r.fail_after_by_minutes).to be == Reoccurrence::DAY_MINUTES
    end

    it ', should create reoccurrence for hourly' do
      r = Reoccurrence.create_new_occurrence(Reoccurrence.hourly, Reoccurrence.hourly)
      expect(r.run_every_by_minutes).to be == Reoccurrence::HOUR_MINUTES
    end
  end
end
