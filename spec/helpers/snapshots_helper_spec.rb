require 'spec_helper'

include FactoryGirl::Syntax::Methods

# This test file is for new algorithms for emails network - part of V3 version

describe SnapshotsHelper, type: :helper do
  
  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end
  
  describe 'test method: get_interval_type_string()' do
    it 'should return string representing the interval' do
      res = get_interval_type_string(1)
      expect(res).to eq('month')
    end
    it 'should return string representing the interval' do
      res = get_interval_type_string(2)
      expect(res).to eq('quarter')
    end
    it 'should return string representing the interval' do
      res = get_interval_type_string(3)
      expect(res).to eq('half_year')
    end
    it 'should return string representing the interval' do
      res = get_interval_type_string(4)
      expect(res).to eq('year')
    end
  end

  # describe 'test method: get_emails_volume_scores() - test quarter averages' do
    
  #   before(:all) do
  #     @cid = 2
  #     cmid = 6
  #     aid = 707

  #     em1 = 'p11@email.com'
  #     em2 = 'p22@email.com'
  #     em3 = 'p33@email.com'
  #     em4 = 'p44@email.com'

  #     @g1 = FactoryGirl.create(:group)
  #     @g2 = FactoryGirl.create(:group)

  #     @e1 = FactoryGirl.create(:employee, email: em1, group_id: @g1.id)
  #     @e2 = FactoryGirl.create(:employee, email: em2, group_id: @g1.id)
  #     @e3 = FactoryGirl.create(:employee, email: em3, group_id: @g2.id)
  #     @e4 = FactoryGirl.create(:employee, email: em4, group_id: @g2.id)

  #     # Snapshots
  #     # June - Q2
  #     @s1 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-01 18:00:00')
  #     @s2 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-08 18:00:00')
  #     @s3 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-17 18:00:00')
  #     @s4 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-28 18:00:00')
      
  #     # August - Q3
  #     @s5 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-08-01 18:00:00')
  #     @s6 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-08-08 18:00:00')
  #     @s7 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-08-17 18:00:00')
  #     @s8 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-08-28 18:00:00')
      
  #     # September - Q3
  #     @s9 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-01 18:00:00')
  #     @s10 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-08 18:00:00')
  #     @s11 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-17 18:00:00')
  #     @s12 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-28 18:00:00')
      
  #     # October - Q4
  #     @s13 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-01 18:00:00')
  #     @s14 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-08 18:00:00')
  #     @s15 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-17 18:00:00')
  #     @s16 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-28 18:00:00')

  #     # Emails volume scores
  #     @score1 = create_cds_metric_score(10, @e1.group_id, @e1.id, @cid, @s1.id, cmid, aid)
  #     @score2 = create_cds_metric_score(20, @e2.group_id, @e2.id, @cid, @s2.id, cmid, aid)
  #     @score3 = create_cds_metric_score(30, @e3.group_id, @e3.id, @cid, @s3.id, cmid, aid)
  #     @score4 = create_cds_metric_score(40, @e4.group_id, @e4.id, @cid, @s4.id, cmid, aid)
      
  #     @score5 = create_cds_metric_score(20, @e1.group_id, @e1.id, @cid, @s5.id, cmid, aid)
  #     @score6 = create_cds_metric_score(30, @e2.group_id, @e2.id, @cid, @s6.id, cmid, aid)
  #     @score7 = create_cds_metric_score(40, @e3.group_id, @e3.id, @cid, @s7.id, cmid, aid)
  #     @score8 = create_cds_metric_score(50, @e4.group_id, @e4.id, @cid, @s8.id, cmid, aid)
      
  #     @score9 = create_cds_metric_score(30, @e1.group_id, @e1.id, @cid, @s9.id, cmid, aid)
  #     @score10 = create_cds_metric_score(40, @e2.group_id, @e2.id, @cid, @s10.id, cmid, aid)
  #     @score11 = create_cds_metric_score(50, @e3.group_id, @e3.id, @cid, @s11.id, cmid, aid)
  #     @score12 = create_cds_metric_score(60, @e4.group_id, @e4.id, @cid, @s12.id, cmid, aid)

  #     @score13 = create_cds_metric_score(40, @e1.group_id, @e1.id, @cid, @s13.id, cmid, aid)
  #     @score14 = create_cds_metric_score(50, @e2.group_id, @e2.id, @cid, @s14.id, cmid, aid)
  #     @score15 = create_cds_metric_score(60, @e3.group_id, @e3.id, @cid, @s15.id, cmid, aid)
  #     @score16 = create_cds_metric_score(70, @e4.group_id, @e4.id, @cid, @s16.id, cmid, aid)
  #   end

  #   describe 'test quarters averages' do
      
  #     before(:all) do
  #       gids = [@g1.id, @g2.id]
  #       @res = get_emails_volume_scores(2, gids, @cid)
  #       # puts "@res ? #{@res.inspect}"
  #     end

  #     it 'should return correct number of averages per intervals' do
  #       expect(@res.length).to eq(3)
  #     end

  #     it 'should return correct interval name' do
  #       expect(@res[0][:time_period]).to eq('Q2/16')
  #     end

  #     it 'should return correct average' do
  #       correct_avg = 40
  #       expect(@res[0][:score] - correct_avg).to be < 0.1
  #     end

  #     it 'should return correct average' do
  #       correct_avg = 55
  #       expect(@res[1][:score] - correct_avg).to be < 0.1
  #     end

  #     it 'should show larger average' do
  #       expect(@res[0][:score]).to be < @res[1][:score]
  #     end

  #     it 'should show larger average' do
  #       expect(@res[0][:score]).to be < @res[2][:score]
  #     end
  #   end
  # end

  # describe 'test method: get_emails_volume_scores() - test half years averages' do
  
  #   before(:all) do
  #     @cid = 2
  #     cmid = 6
  #     aid = 707

  #     em1 = 'p11@email.com'
  #     em2 = 'p22@email.com'
  #     em3 = 'p33@email.com'
  #     em4 = 'p44@email.com'

  #     @g1 = FactoryGirl.create(:group)
  #     @g2 = FactoryGirl.create(:group)

  #     @e1 = FactoryGirl.create(:employee, email: em1, group_id: @g1.id)
  #     @e2 = FactoryGirl.create(:employee, email: em2, group_id: @g1.id)
  #     @e3 = FactoryGirl.create(:employee, email: em3, group_id: @g2.id)
  #     @e4 = FactoryGirl.create(:employee, email: em4, group_id: @g2.id)

  #     # Snapshots
  #     # June - H1/16
  #     @s1 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-05-01 18:00:00')
  #     @s2 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-05-08 18:00:00')
  #     @s3 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-05-17 18:00:00')
  #     @s4 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-05-28 18:00:00')
      
  #     # August - H1/16
  #     @s5 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-01 18:00:00')
  #     @s6 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-08 18:00:00')
  #     @s7 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-17 18:00:00')
  #     @s8 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-28 18:00:00')
      
  #     # September - H2/16
  #     @s9 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-01 18:00:00')
  #     @s10 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-08 18:00:00')
  #     @s11 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-17 18:00:00')
  #     @s12 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-28 18:00:00')
      
  #     # October - H2/16
  #     @s13 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-01 18:00:00')
  #     @s14 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-08 18:00:00')
  #     @s15 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-17 18:00:00')
  #     @s16 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-28 18:00:00')

  #     # November - H2/16
  #     @s17 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-11-01 18:00:00')
  #     @s18 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-11-08 18:00:00')
  #     @s19 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-11-17 18:00:00')
  #     @s20 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-11-28 18:00:00')

  #     # January - H1/17
  #     @s21 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-01-01 18:00:00')
  #     @s22 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-01-08 18:00:00')
  #     @s23 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-01-17 18:00:00')
  #     @s24 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-01-28 18:00:00')

  #     # Emails volume scores
  #     # June - H1/16
  #     @score1 = create_cds_metric_score(10, @e1.group_id, @e1.id, @cid, @s1.id, cmid, aid)
  #     @score2 = create_cds_metric_score(20, @e2.group_id, @e2.id, @cid, @s2.id, cmid, aid)
  #     @score3 = create_cds_metric_score(30, @e3.group_id, @e3.id, @cid, @s3.id, cmid, aid)
  #     @score4 = create_cds_metric_score(0, @e4.group_id, @e4.id, @cid, @s4.id, cmid, aid)

  #     # August - H1/16
  #     @score5 = create_cds_metric_score(20, @e1.group_id, @e1.id, @cid, @s5.id, cmid, aid)
  #     @score6 = create_cds_metric_score(30, @e2.group_id, @e2.id, @cid, @s6.id, cmid, aid)
  #     @score7 = create_cds_metric_score(40, @e3.group_id, @e3.id, @cid, @s7.id, cmid, aid)
  #     @score8 = create_cds_metric_score(50, @e4.group_id, @e4.id, @cid, @s8.id, cmid, aid)

  #     # September - H2/16
  #     @score9 = create_cds_metric_score(30, @e1.group_id, @e1.id, @cid, @s9.id, cmid, aid)
  #     @score10 = create_cds_metric_score(40, @e2.group_id, @e2.id, @cid, @s10.id, cmid, aid)
  #     @score11 = create_cds_metric_score(50, @e3.group_id, @e3.id, @cid, @s11.id, cmid, aid)
  #     @score12 = create_cds_metric_score(60, @e4.group_id, @e4.id, @cid, @s12.id, cmid, aid)

  #     # October - H2/16
  #     @score13 = create_cds_metric_score(40, @e1.group_id, @e1.id, @cid, @s13.id, cmid, aid)
  #     @score14 = create_cds_metric_score(50, @e2.group_id, @e2.id, @cid, @s14.id, cmid, aid)
  #     @score15 = create_cds_metric_score(60, @e3.group_id, @e3.id, @cid, @s15.id, cmid, aid)
  #     @score16 = create_cds_metric_score(70, @e4.group_id, @e4.id, @cid, @s16.id, cmid, aid)
      
  #     # November - H2/16
  #     @score17 = create_cds_metric_score(100, @e1.group_id, @e1.id, @cid, @s17.id, cmid, aid)
  #     @score18 = create_cds_metric_score(500, @e2.group_id, @e2.id, @cid, @s18.id, cmid, aid)
  #     @score19 = create_cds_metric_score(600, @e3.group_id, @e3.id, @cid, @s19.id, cmid, aid)
  #     @score20 = create_cds_metric_score(700, @e4.group_id, @e4.id, @cid, @s20.id, cmid, aid)

  #     # January - H1/17
  #     @score21 = create_cds_metric_score(100, @e1.group_id, @e1.id, @cid, @s21.id, cmid, aid)
  #     @score22 = create_cds_metric_score(500, @e2.group_id, @e2.id, @cid, @s22.id, cmid, aid)
  #     @score23 = create_cds_metric_score(600, @e3.group_id, @e3.id, @cid, @s23.id, cmid, aid)
  #     @score24 = create_cds_metric_score(700, @e4.group_id, @e4.id, @cid, @s24.id, cmid, aid)
  #   end

  #   describe 'test half years averages' do
      
  #     before(:all) do
  #       gids = [@g1.id, @g2.id]
  #       @res = get_emails_volume_scores(3, gids, @cid)
  #       # puts "@res ? #{@res.inspect}"
  #     end

  #     it 'should return correct number of averages per intervals' do
  #       expect(@res.length).to eq(3)
  #     end

  #     it 'should return correct interval name' do
  #       expect(@res[0][:time_period]).to eq('H1/16')
  #     end

  #     it 'should return correct average' do
  #       correct_avg = 25
  #       expect(@res[0][:score] - correct_avg).to be < 0.1
  #     end

  #     it 'should show larger average' do
  #       expect(@res[0][:score]).to be < @res[1][:score]
  #     end

  #     it 'should show larger average' do
  #       expect(@res[1][:score]).to be < @res[2][:score]
  #     end
  #   end
  # end

  describe 'test method: get_emails_volume_scores() - test year averages' do
  
    before(:all) do
      @cid = 2
      cmid = 6
      aid = 707

      # Snapshots
      # June - 2015
      @s1 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-05-01 18:00:00')
      @s2 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-05-08 18:00:00')
      @s3 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-05-17 18:00:00')
      @s4 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-05-28 18:00:00')
      
      # August - 2015
      @s5 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-06-01 18:00:00')
      @s6 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-06-08 18:00:00')
      @s7 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-06-17 18:00:00')
      @s8 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2015-06-28 18:00:00')
      
      # September - 2016
      @s9 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp:  '2016-09-01 18:00:00')
      @s10 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-08 18:00:00')
      @s11 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-17 18:00:00')
      @s12 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-28 18:00:00')
      
      # October - 2016
      @s13 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-01 18:00:00')
      @s14 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-08 18:00:00')
      @s15 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-17 18:00:00')
      @s16 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-28 18:00:00')

      # November - 2016
      @s17 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-11-01 18:00:00')
      @s18 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-11-08 18:00:00')
      @s19 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-11-17 18:00:00')
      @s20 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-11-28 18:00:00')

      # January - 2017
      @s21 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-01-01 18:00:00')
      @s22 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-01-08 18:00:00')
      @s23 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-01-17 18:00:00')
      @s24 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2017-01-28 18:00:00')

      # Groups
      @g1 = FactoryGirl.create(:group, snapshot_id: @s4.id, external_id: 'group_1')
      @g2 = FactoryGirl.create(:group, snapshot_id: @s4.id, external_id: 'group_2')
      @g3 = FactoryGirl.create(:group, snapshot_id: @s8.id, external_id: 'group_1')
      @g4 = FactoryGirl.create(:group, snapshot_id: @s8.id, external_id: 'group_2')
      @g5 = FactoryGirl.create(:group, snapshot_id: @s12.id, external_id: 'group_1')
      @g6 = FactoryGirl.create(:group, snapshot_id: @s12.id, external_id: 'group_2')
      @g7 = FactoryGirl.create(:group, snapshot_id: @s16.id, external_id: 'group_1')
      @g8 = FactoryGirl.create(:group, snapshot_id: @s16.id, external_id: 'group_2')

      em1 = 'p11@email.com'
      em2 = 'p22@email.com'
      em3 = 'p33@email.com'
      em4 = 'p44@email.com'

      @e1 = FactoryGirl.create(:employee, email: em1, group_id: @g1.id)
      @e2 = FactoryGirl.create(:employee, email: em2, group_id: @g1.id)
      @e3 = FactoryGirl.create(:employee, email: em3, group_id: @g2.id)
      @e4 = FactoryGirl.create(:employee, email: em4, group_id: @g2.id)

      # Emails volume scores
      # June - 2015
      @score1 = create_cds_metric_score(10, @e1.group_id, @e1.id, @cid, @s1.id, cmid, aid)
      @score2 = create_cds_metric_score(20, @e2.group_id, @e2.id, @cid, @s2.id, cmid, aid)
      @score3 = create_cds_metric_score(30, @e3.group_id, @e3.id, @cid, @s3.id, cmid, aid)
      @score4 = create_cds_metric_score(100, @e4.group_id, @e4.id, @cid, @s4.id, cmid, aid)

      # August - 2015
      @score5 = create_cds_metric_score(20, @e1.group_id, @e1.id, @cid, @s5.id, cmid, aid)
      @score6 = create_cds_metric_score(30, @e2.group_id, @e2.id, @cid, @s6.id, cmid, aid)
      @score7 = create_cds_metric_score(40, @e3.group_id, @e3.id, @cid, @s7.id, cmid, aid)
      @score8 = create_cds_metric_score(50, @e4.group_id, @e4.id, @cid, @s8.id, cmid, aid)
      
      # September - 2016
      @score9 = create_cds_metric_score(30, @e1.group_id, @e1.id, @cid, @s9.id, cmid, aid)
      @score10 = create_cds_metric_score(40, @e2.group_id, @e2.id, @cid, @s10.id, cmid, aid)
      @score11 = create_cds_metric_score(50, @e3.group_id, @e3.id, @cid, @s11.id, cmid, aid)
      @score12 = create_cds_metric_score(60, @e4.group_id, @e4.id, @cid, @s12.id, cmid, aid)

      # October - 2016
      @score13 = create_cds_metric_score(40, @e1.group_id, @e1.id, @cid, @s13.id, cmid, aid)
      @score14 = create_cds_metric_score(50, @e2.group_id, @e2.id, @cid, @s14.id, cmid, aid)
      @score15 = create_cds_metric_score(60, @e3.group_id, @e3.id, @cid, @s15.id, cmid, aid)
      @score16 = create_cds_metric_score(70, @e4.group_id, @e4.id, @cid, @s16.id, cmid, aid)

      # November - 2016
      @score17 = create_cds_metric_score(100, @e1.group_id, @e1.id, @cid, @s17.id, cmid, aid)
      @score18 = create_cds_metric_score(500, @e2.group_id, @e2.id, @cid, @s18.id, cmid, aid)
      @score19 = create_cds_metric_score(600, @e3.group_id, @e3.id, @cid, @s19.id, cmid, aid)
      @score20 = create_cds_metric_score(700, @e4.group_id, @e4.id, @cid, @s20.id, cmid, aid)

      # January - 2017
      @score21 = create_cds_metric_score(100, @e1.group_id, @e1.id, @cid, @s21.id, cmid, aid)
      @score22 = create_cds_metric_score(500, @e2.group_id, @e2.id, @cid, @s22.id, cmid, aid)
      @score23 = create_cds_metric_score(600, @e3.group_id, @e3.id, @cid, @s23.id, cmid, aid)
      @score24 = create_cds_metric_score(700, @e4.group_id, @e4.id, @cid, @s24.id, cmid, aid)
    end

    describe 'test year averages' do
      
      before(:all) do
        gids = [@g7.id, @g8.id]
        @res = get_emails_volume_scores(4, gids, @cid)
        # puts "@res ? #{@res.inspect}"
      end

      it 'should return correct number of averages per intervals' do
        expect(@res.length).to eq(3)
      end

      it 'should return correct interval name' do
        expect(@res[0][:time_period]).to eq('2015')
      end

      it 'should return correct average' do
        correct_avg = 75
        expect(@res[0][:score] - correct_avg).to be < 0.1
      end

      it 'should show larger average' do
        expect(@res[0][:score]).to be < @res[1][:score]
      end

      it 'should show larger average' do
        expect(@res[1][:score]).to be < @res[2][:score]
      end
    end
  end

  # describe 'test method: get_time_spent_in_meetings()' do
    
  #   before(:all) do
  #     @cid = 2
  #     cmid = 6
  #     aid = 707

  #     em1 = 'p11@email.com'
  #     em2 = 'p22@email.com'
  #     em3 = 'p33@email.com'
  #     em4 = 'p44@email.com'

  #     @g1 = FactoryGirl.create(:group)
  #     @g2 = FactoryGirl.create(:group)

  #     @e1 = FactoryGirl.create(:employee, email: em1, group_id: @g1.id)
  #     @e2 = FactoryGirl.create(:employee, email: em2, group_id: @g1.id)
  #     @e3 = FactoryGirl.create(:employee, email: em3, group_id: @g2.id)
  #     @e4 = FactoryGirl.create(:employee, email: em4, group_id: @g2.id)

  #     # Snapshots
  #     # June - Q2
  #     @s1 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-01 18:00:00')
  #     @s2 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-08 18:00:00')
  #     @s3 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-17 18:00:00')
  #     @s4 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-06-28 18:00:00')
      
  #     # August - Q3
  #     @s5 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-08-01 18:00:00')
  #     @s6 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-08-08 18:00:00')
  #     @s7 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-08-17 18:00:00')
  #     @s8 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-08-28 18:00:00')
      
  #     # September - Q3
  #     @s9 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-01 18:00:00')
  #     @s10 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-08 18:00:00')
  #     @s11 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-17 18:00:00')
  #     @s12 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-09-28 18:00:00')
      
  #     # October - Q4
  #     @s13 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-01 18:00:00')
  #     @s14 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-08 18:00:00')
  #     @s15 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-17 18:00:00')
  #     @s16 = FactoryGirl.create(:snapshot, company_id: @cid, timestamp: '2016-10-28 18:00:00')

  #     # Emails volume scores
  #     @score1 = create_cds_metric_score(10, @e1.group_id, @e1.id, @cid, @s1.id, cmid, aid)
  #     @score2 = create_cds_metric_score(20, @e2.group_id, @e2.id, @cid, @s2.id, cmid, aid)
  #     @score3 = create_cds_metric_score(30, @e3.group_id, @e3.id, @cid, @s3.id, cmid, aid)
  #     @score4 = create_cds_metric_score(40, @e4.group_id, @e4.id, @cid, @s4.id, cmid, aid)
      
  #     @score5 = create_cds_metric_score(20, @e1.group_id, @e1.id, @cid, @s5.id, cmid, aid)
  #     @score6 = create_cds_metric_score(30, @e2.group_id, @e2.id, @cid, @s6.id, cmid, aid)
  #     @score7 = create_cds_metric_score(40, @e3.group_id, @e3.id, @cid, @s7.id, cmid, aid)
  #     @score8 = create_cds_metric_score(50, @e4.group_id, @e4.id, @cid, @s8.id, cmid, aid)
      
  #     @score9 = create_cds_metric_score(30, @e1.group_id, @e1.id, @cid, @s9.id, cmid, aid)
  #     @score10 = create_cds_metric_score(40, @e2.group_id, @e2.id, @cid, @s10.id, cmid, aid)
  #     @score11 = create_cds_metric_score(50, @e3.group_id, @e3.id, @cid, @s11.id, cmid, aid)
  #     @score12 = create_cds_metric_score(60, @e4.group_id, @e4.id, @cid, @s12.id, cmid, aid)

  #     @score13 = create_cds_metric_score(40, @e1.group_id, @e1.id, @cid, @s13.id, cmid, aid)
  #     @score14 = create_cds_metric_score(50, @e2.group_id, @e2.id, @cid, @s14.id, cmid, aid)
  #     @score15 = create_cds_metric_score(60, @e3.group_id, @e3.id, @cid, @s15.id, cmid, aid)
  #     @score16 = create_cds_metric_score(70, @e4.group_id, @e4.id, @cid, @s16.id, cmid, aid)
  #   end

  #   describe 'test quarters averages' do
      
  #     before(:all) do
  #       gids = [@g1.id, @g2.id]
  #       @res = get_emails_volume_scores(2, gids, @cid)
  #       # puts "@res ? #{@res.inspect}"
  #     end

  #     it 'should return correct number of averages per intervals' do
  #       expect(@res.length).to eq(3)
  #     end

  #     it 'should return correct interval name' do
  #       expect(@res[0][:time_period]).to eq('Q2/16')
  #     end

  #     it 'should return correct average' do
  #       correct_avg = 40
  #       expect(@res[0][:score] - correct_avg).to be < 0.1
  #     end

  #     it 'should return correct average' do
  #       correct_avg = 55
  #       expect(@res[1][:score] - correct_avg).to be < 0.1
  #     end

  #     it 'should show larger average' do
  #       expect(@res[0][:score]).to be < @res[1][:score]
  #     end

  #     it 'should show larger average' do
  #       expect(@res[0][:score]).to be < @res[2][:score]
  #     end
  #   end
  # end

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