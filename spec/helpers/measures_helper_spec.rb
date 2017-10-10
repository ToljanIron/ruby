require 'spec_helper'

include FactoryGirl::Syntax::Methods

# This test file is for new algorithms for emails network - part of V3 version

describe MeasuresHelper, type: :helper do
  
  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end
  
  describe 'test method: get_interval_type_string()' do
    it 'should return string representing the interval month' do
      res = get_interval_type_string(1)
      expect(res).to eq('month')
    end
    it 'should return string representing the interval quarter' do
      res = get_interval_type_string(2)
      expect(res).to eq('quarter')
    end
    it 'should return string representing the interval half year' do
      res = get_interval_type_string(3)
      expect(res).to eq('half_year')
    end
    it 'should return string representing the interval year' do
      res = get_interval_type_string(4)
      expect(res).to eq('year')
    end
  end

  describe 'test method: get_time_picker_data_by_aid()' do
  
    before(:each) do
      @cid = 2
      cmid = 6 #metric id
      @aid = 707
      @sids = []

      # Snapshots
      # May - 2015
      @sids << @sid1 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-05-28 18:00:00').id
      
      # June - 2015
      @sids << @sid2 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-06-28 18:00:00').id
      
      # August - 2016
      @sids << @sid3 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-08-28 18:00:00').id

      # Groups
      @gid1 = FactoryGirl.create(:group, snapshot_id: @sid1, external_id: 'group_1').id
      @gid2 = FactoryGirl.create(:group, snapshot_id: @sid1, external_id: 'group_2').id
      @gid3 = FactoryGirl.create(:group, snapshot_id: @sid2, external_id: 'group_1').id
      @gid4 = FactoryGirl.create(:group, snapshot_id: @sid2, external_id: 'group_2').id
      @gid5 = FactoryGirl.create(:group, snapshot_id: @sid3, external_id: 'group_1').id
      @gid6 = FactoryGirl.create(:group, snapshot_id: @sid3, external_id: 'group_2').id      

      @e1 = FactoryGirl.create(:employee, email: 'p11@email.com', group_id: @gid1)
      @e2 = FactoryGirl.create(:employee, email: 'p22@email.com', group_id: @gid1)
      @e3 = FactoryGirl.create(:employee, email: 'p33@email.com', group_id: @gid2)
      @e4 = FactoryGirl.create(:employee, email: 'p44@email.com', group_id: @gid2)

      # Emails volume scores
      # May - 2015
      @score1 = create_cds_metric_score(10, @e1.group_id, @e1.id, @cid, @sid1, cmid, @aid)
      @score2 = create_cds_metric_score(20, @e2.group_id, @e2.id, @cid, @sid1, cmid, @aid)
      @score3 = create_cds_metric_score(30, @e3.group_id, @e3.id, @cid, @sid1, cmid, @aid)
      @score4 = create_cds_metric_score(100, @e4.group_id, @e4.id, @cid, @sid1, cmid, @aid)

      # June - 2015
      @score5 = create_cds_metric_score(20, @e1.group_id, @e1.id, @cid, @sid2, cmid, @aid)
      @score6 = create_cds_metric_score(30, @e2.group_id, @e2.id, @cid, @sid2, cmid, @aid)
      @score7 = create_cds_metric_score(40, @e3.group_id, @e3.id, @cid, @sid2, cmid, @aid)
      @score8 = create_cds_metric_score(50, @e4.group_id, @e4.id, @cid, @sid2, cmid, @aid)

      # August - 2015
      @score9 = create_cds_metric_score(10, @e1.group_id, @e1.id, @cid, @sid3, cmid, @aid)
      @score10 = create_cds_metric_score(10, @e2.group_id, @e2.id, @cid, @sid3, cmid, @aid)
      @score11 = create_cds_metric_score(100, @e3.group_id, @e3.id, @cid, @sid3, cmid, @aid)
      @score12 = create_cds_metric_score(95, @e4.group_id, @e4.id, @cid, @sid3, cmid, @aid)
    end

    it 'should return correct number of averages per intervals - month' do
      gids = [@gid5, @gid6]
      res = get_time_picker_data_by_aid(@cid, @sids, gids, 1, @aid)
      # Number of results (averages) should be with respect to what scores we have. If there
      # are a lot of snapshots, but only scores for 2 snapshots, we should get averages for
      # these 2 snapshots
      expect(res.length).to eq(3)
    end

    it 'should return correct time period - month' do
      gids = [@gid5, @gid6]
      res = get_time_picker_data_by_aid(@cid, @sids, gids, 1, @aid)
      expect(res[res.length - 1]['time_period']).to eq('Aug/15')
    end

    it 'should return correct average - month' do
      gids = [@gid5, @gid6]
      res = get_time_picker_data_by_aid(@cid, @sids, gids, 1, @aid)
      expect(res[res.length - 1]['score'] - 53.75).to be < 0.01
    end

    it 'should return correct number of averages per intervals - quarter' do
      gids = [@gid5, @gid6]
      res = get_time_picker_data_by_aid(@cid, @sids, gids, 2, @aid)
      expect(res.length).to eq(2)
    end

    it 'should return correct time period - quarter' do
      gids = [@gid5, @gid6]
      res = get_time_picker_data_by_aid(@cid, @sids, gids, 2, @aid)
      expect(res[res.length - 1]['time_period']).to eq('Q3/15')
    end

    it 'should return correct average - For Q2/15' do
      gids = [@gid5, @gid6]
      res = get_time_picker_data_by_aid(@cid, @sids, gids, 2, @aid)
      expect(res[0]['score'] - 37.5).to be < 0.01
    end
  end

  describe 'test method: get_gauge_level()' do
    it 'should return integer representing LOW gauge level' do
      res = get_gauge_level(-2)
      expect(res).to eq(0)
    end
    it 'should return integer representing MEDIUM gauge level' do
      res = get_gauge_level(0.2)
      expect(res).to eq(1)
    end
    it 'should return integer representing HIGH gauge level' do
      res = get_gauge_level(10)
      expect(res).to eq(2)
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