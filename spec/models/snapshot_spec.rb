require 'spec_helper'

describe Snapshot, :type => :model do

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'create snampshot by date do' do
    it 'create_company_snapshot_by_weeks' do
      sid = Snapshot::create_snapshot_by_weeks(2, '2016-04-03')
      expect(sid.name).to eq('2016-14')
      expect(sid.status).to eq('before_precalculate')
    end

    it 'should create only a single snapshot when triggered twice on same day' do
      Snapshot::create_snapshot_by_weeks(2, '2016-04-03')
      expect(Snapshot.count).to eq(1)
      Snapshot::create_snapshot_by_weeks(2, '2016-04-03')
      expect(Snapshot.count).to eq(1)
    end

    it 'should create only a single snapshot when triggered twice on same day' do
      Snapshot::create_snapshot_by_weeks(2, '2016-04-03')
      expect(Snapshot.count).to eq(1)
      Snapshot::create_snapshot_by_weeks(2, '2016-04-04')
      expect(Snapshot.count).to eq(1)
    end

    it 'should create only a single snapshot when triggered twice on same day' do
      Snapshot::create_snapshot_by_weeks(2, '2016-04-03')
      expect(Snapshot.count).to eq(1)
      Snapshot::create_snapshot_by_weeks(2, '2016-04-14')
      expect(Snapshot.count).to eq(2)
    end
  end

  describe 'last_snapshot_of_company' do
    before do
      @cid = FactoryBot.create(:company).id
    end

    it 'should return nil if no company id given' do
      expect( Snapshot.last_snapshot_of_company(nil) ).to be_nil
    end

    it 'shuld create a new snapshot if snapshot does not exist' do
      Snapshot.last_snapshot_of_company(@cid)
      expect(Snapshot.count).to eq(1)
    end

    it 'should return last snapshot if multiple snapshots exist' do
      FactoryBot.create(:snapshot, timestamp: Time.now)
      FactoryBot.create(:snapshot, timestamp: 1.week.from_now)
      last_snapshot = FactoryBot.create(:snapshot, timestamp: 2.weeks.from_now)
      sid = Snapshot.last_snapshot_of_company(@cid)
      expect(sid).to eq(last_snapshot.id)
    end
  end

  describe 'compare_periods' do
    it 'should compare by month with different years' do
      expect(Snapshot.compare_periods('Oct/17', 'Oct/18')).to eq(-1)
      expect(Snapshot.compare_periods('Oct/19', 'Oct/18')).to eq(1)
    end

    it 'should compare by month with same years' do
      expect(Snapshot.compare_periods('Nov/17', 'Oct/17')).to eq(1)
      expect(Snapshot.compare_periods('Jan/17', 'Oct/17')).to eq(-1)
      expect(Snapshot.compare_periods('Jan/17', 'Jan/17')).to eq(0)
    end

    it 'should compare by years' do
      expect(Snapshot.compare_periods('2017', '2019')).to eq(-1)
      expect(Snapshot.compare_periods('2019', '2019')).to eq(0)
      expect(Snapshot.compare_periods('2023', '2019')).to eq(1)
    end

    it 'should compare by quarter' do
      expect(Snapshot.compare_periods('Q1/17', 'Q1/18')).to eq(-1)
      expect(Snapshot.compare_periods('Q2/20', 'Q4/20')).to eq(-1)
    end

    it 'should compare by half year' do
      expect(Snapshot.compare_periods('H1/18', 'H1/16')).to eq(1)
      expect(Snapshot.compare_periods('H2/20', 'H1/20')).to eq(1)
      expect(Snapshot.compare_periods('H2/20', 'H2/20')).to eq(0)
    end
  end

end
