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
      @cid = FactoryGirl.create(:company).id
    end

    it 'should return nil if no company id given' do
      expect( Snapshot.last_snapshot_of_company(nil) ).to be_nil
    end

    it 'shuld create a new snapshot if snapshot does not exist' do
      Snapshot.last_snapshot_of_company(@cid)
      expect(Snapshot.count).to eq(1)
    end

    it 'should return last snapshot if multiple snapshots exist' do
      FactoryGirl.create(:snapshot)
      FactoryGirl.create(:snapshot)
      last_snapshot = FactoryGirl.create(:snapshot)
      sid = Snapshot.last_snapshot_of_company(@cid)
      expect(sid).to eq(last_snapshot.id)
    end
  end

end
