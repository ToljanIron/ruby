require 'spec_helper'

include FactoryGirl::Syntax::Methods

# This test file is for new algorithms for emails network - part of V3 version

describe SnapshotsHelper, type: :helper do
  
  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end
  
  describe 'test method: get_relevant_snapshots()' do
    before(:each) do
      @cid = 1
      # May
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-05-1 18:00:00')
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-05-8 18:00:00')
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-05-15 18:00:00')
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-05-28 18:00:00')
      
      # June
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-06-1 18:00:00')
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-06-8 18:00:00')
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-06-15 18:00:00')
      
      # July
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-07-1 18:00:00')
      
      # August
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-08-10 18:00:00')
      FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-08-20 18:00:00')
    end
    it 'should return last snapshots of each month' do
      res = get_relevant_snapshots(@cid, 20)
      expect(res.length).to eq(4)
    end
  end
end

def create_cds_metric_score(score, gid, eid, cid, sid, company_metric_id, aid)
  s = FactoryGirl.create(
    :cds_metric_score,
    score: score,
    group_id: gid,
    employee_id: eid,
    company_id: cid,
    snapshot_id: sid,
    company_metric_id: company_metric_id,
    algorithm_id: aid
    )
  return s
end