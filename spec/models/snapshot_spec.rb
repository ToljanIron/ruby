require 'spec_helper'

describe Snapshot, :type => :model do

  describe 'create snampshot by date do' do

    after do
      DatabaseCleaner.clean_with(:truncation)
    end
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

end
