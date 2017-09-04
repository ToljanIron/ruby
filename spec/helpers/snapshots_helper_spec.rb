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
      res = get_interval_type_string(0)
      expect(res).to eq('month')
    end
    it 'should return string representing the interval' do
      res = get_interval_type_string(1)
      expect(res).to eq('quarter')
    end
    it 'should return string representing the interval' do
      res = get_interval_type_string(2)
      expect(res).to eq('half_year')
    end
    it 'should return string representing the interval' do
      res = get_interval_type_string(3)
      expect(res).to eq('year')
    end
  end

  describe 'test method: get_average_for_time_interval()' do
    
    describe '1' do
      before(:all) do
        @time_period = 'Q2/16'
        data = [
          {'score' => 10, 'time_period' => @time_period},
          {'score' => 20, 'time_period' => @time_period},
          {'score' => 30, 'time_period' => @time_period}
        ]
        
        @correct_avg = 20
        @averages = get_average_for_time_interval(data)
      end

      it 'should return correct period name' do
        expect(@averages[0][:time_period]).to eq(@time_period)
      end

      it 'should return correct average' do
        expect(@averages[0][:score] - @correct_avg).to be < 0.1
      end
    end

    describe '2' do
      before(:all) do
        @time_period1 = 'Q2/16'
        @time_period2 = 'Q3/16'
        
        data = [
          {'score' => 0,   'time_period' => @time_period1},
          {'score' => 100, 'time_period' => @time_period1},
          {'score' => 200, 'time_period' => @time_period1},
          {'score' => 0,   'time_period' => @time_period2},
          {'score' => 100, 'time_period' => @time_period2}
        ]
        
        @correct_avg1 = 100
        @correct_avg2 = 50

        @averages = get_average_for_time_interval(data)
      end

      it 'should return correct period name' do
        expect(@averages[0][:time_period]).to eq(@time_period1)
      end

      it 'should return correct average' do
        expect(@averages[0][:score] - @correct_avg1).to be < 0.1
      end

      it 'should return correct period name' do
        expect(@averages[1][:time_period]).to eq(@time_period2)
      end

      it 'should return correct average' do
        expect(@averages[1][:score] - @correct_avg2).to be < 0.1
      end

      it 'should show larger average' do
        expect(@averages[0][:score]).to be > @averages[1][:score]
      end
    end

    describe '3' do
      before(:all) do
        @time_period1 = 'Q2/16'
        @time_period2 = 'Q3/16'
        @time_period3 = 'Q4/16'
        
        data = [
          {'score' => 0,   'time_period' => @time_period1},
          {'score' => 100, 'time_period' => @time_period1},
          {'score' => 200, 'time_period' => @time_period1},
          {'score' => 0,   'time_period' => @time_period2},
          {'score' => 100, 'time_period' => @time_period2},
          {'score' => 500, 'time_period' => @time_period3}
        ]
        
        @correct_avg1 = 100
        @correct_avg2 = 50
        @correct_avg3 = 500

        @averages = get_average_for_time_interval(data)
      end

      it 'should return correct period name' do
        expect(@averages[0][:time_period]).to eq(@time_period1)
      end

      it 'should return correct average' do
        expect(@averages[0][:score] - @correct_avg1).to be < 0.1
      end

      it 'should return correct period name' do
        expect(@averages[1][:time_period]).to eq(@time_period2)
      end

      it 'should return correct average' do
        expect(@averages[1][:score] - @correct_avg2).to be < 0.1
      end

      it 'should return correct period name' do
        expect(@averages[2][:time_period]).to eq(@time_period3)
      end

      it 'should return correct average' do
        expect(@averages[2][:score] - @correct_avg3).to be < 0.1
      end

      it 'should show larger average' do
        expect(@averages[2][:score]).to be > @averages[0][:score]
      end
    end

    describe '4' do
      before(:all) do
        @time_period1 = '2015'
        @time_period2 = '2016'
        @time_period3 = '2017'
        
        data = [
          {'score' => 500,  'time_period' => @time_period1},
          {'score' => 1000, 'time_period' => @time_period1},
          {'score' => 2000, 'time_period' => @time_period1},
          {'score' => 0,    'time_period' => @time_period2},
          {'score' => 1000, 'time_period' => @time_period2},
          {'score' => 5000, 'time_period' => @time_period3}
        ]
        
        @correct_avg1 = 1166.6
        @correct_avg2 = 500
        @correct_avg3 = 5000

        @averages = get_average_for_time_interval(data)
      end

      it 'should return correct period name' do
        expect(@averages[0][:time_period]).to eq(@time_period1)
      end

      it 'should return correct average' do
        expect(@averages[0][:score] - @correct_avg1).to be < 0.1
      end

      it 'should return correct period name' do
        expect(@averages[1][:time_period]).to eq(@time_period2)
      end

      it 'should return correct average' do
        expect(@averages[1][:score] - @correct_avg2).to be < 0.1
      end

      it 'should return correct period name' do
        expect(@averages[2][:time_period]).to eq(@time_period3)
      end

      it 'should return correct average' do
        expect(@averages[2][:score] - @correct_avg3).to be < 0.1
      end

      it 'should show larger average' do
        expect(@averages[0][:score]).to be > @averages[1][:score]
      end
    end
  end

  describe 'test method: get_emails_volume_scores() - test quarter averages' do
    
    before(:all) do
      cid = 2
      company_metric_id = 6
      emails_scores_algorithm_id = 707

      # Snapshots
      # June - Q2
      @s1 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-06-01 18:00:00')
      @s2 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-06-08 18:00:00')
      @s3 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-06-17 18:00:00')
      @s4 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-06-28 18:00:00')
      
      # August - Q3
      @s5 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-08-01 18:00:00')
      @s6 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-08-08 18:00:00')
      @s7 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-08-17 18:00:00')
      @s8 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-08-28 18:00:00')
      
      # September - Q3
      @s9 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-01 18:00:00')
      @s10 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-08 18:00:00')
      @s11 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-17 18:00:00')
      @s12 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-28 18:00:00')
      
      # October - Q4
      @s13 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-01 18:00:00')
      @s14 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-08 18:00:00')
      @s15 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-17 18:00:00')
      @s16 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-28 18:00:00')

      # Emails volume scores
      @score1 = FactoryGirl.create(:cds_metric_score, score: 10, company_id: cid, snapshot_id: @s1.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score2 = FactoryGirl.create(:cds_metric_score, score: 20, company_id: cid, snapshot_id: @s2.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score3 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s3.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score4 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s4.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)

      @score5 = FactoryGirl.create(:cds_metric_score, score: 20, company_id: cid, snapshot_id: @s5.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score6 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s6.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score7 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s7.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score8 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s8.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      
      @score9 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s9.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score10 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s10.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score11 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s11.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score12 = FactoryGirl.create(:cds_metric_score, score: 60, company_id: cid, snapshot_id: @s12.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      
      @score13 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s13.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score14 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s14.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score15 = FactoryGirl.create(:cds_metric_score, score: 60, company_id: cid, snapshot_id: @s15.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score16 = FactoryGirl.create(:cds_metric_score, score: 70, company_id: cid, snapshot_id: @s16.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
    end

    describe 'test quarters averages' do
      
      before(:all) do
        @res = get_emails_volume_scores(1)
        puts "@res ? #{@res.inspect}"
      end

      it 'should return correct number of averages per intervals' do
        expect(@res.length).to eq(3)
      end

      it 'should return correct interval name' do
        expect(@res[0][:time_period]).to eq('Q2/16')
      end

      it 'should return correct average' do
        correct_avg = 40
        expect(@res[0][:score] - correct_avg).to be < 0.1
      end

      it 'should return correct average' do
        correct_avg = 55
        expect(@res[1][:score] - correct_avg).to be < 0.1
      end

      it 'should show larger average' do
        expect(@res[0][:score]).to be < @res[1][:score]
      end

      it 'should show larger average' do
        expect(@res[0][:score]).to be < @res[2][:score]
      end
    end
  end

  describe 'test method: get_emails_volume_scores() - test half years averages' do
  
    before(:all) do
      cid = 2
      company_metric_id = 6
      emails_scores_algorithm_id = 707

      # Snapshots
      # June - H1/16
      @s1 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-05-01 18:00:00')
      @s2 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-05-08 18:00:00')
      @s3 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-05-17 18:00:00')
      @s4 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-05-28 18:00:00')
      
      # August - H1/16
      @s5 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-06-01 18:00:00')
      @s6 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-06-08 18:00:00')
      @s7 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-06-17 18:00:00')
      @s8 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-06-28 18:00:00')
      
      # September - H2/16
      @s9 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-01 18:00:00')
      @s10 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-08 18:00:00')
      @s11 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-17 18:00:00')
      @s12 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-28 18:00:00')
      
      # October - H2/16
      @s13 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-01 18:00:00')
      @s14 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-08 18:00:00')
      @s15 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-17 18:00:00')
      @s16 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-28 18:00:00')

      # November - H2/16
      @s17 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-11-01 18:00:00')
      @s18 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-11-08 18:00:00')
      @s19 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-11-17 18:00:00')
      @s20 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-11-28 18:00:00')

      # January - H1/17
      @s21 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2017-01-01 18:00:00')
      @s22 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2017-01-08 18:00:00')
      @s23 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2017-01-17 18:00:00')
      @s24 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2017-01-28 18:00:00')

      # Emails volume scores
      # June - H1/16
      @score1 = FactoryGirl.create(:cds_metric_score, score: 10, company_id: cid, snapshot_id: @s1.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score2 = FactoryGirl.create(:cds_metric_score, score: 20, company_id: cid, snapshot_id: @s2.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score3 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s3.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score4 = FactoryGirl.create(:cds_metric_score, score: 0, company_id: cid, snapshot_id: @s4.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)

      # August - H1/16
      @score5 = FactoryGirl.create(:cds_metric_score, score: 20, company_id: cid, snapshot_id: @s5.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score6 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s6.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score7 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s7.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score8 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s8.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      
      # September - H2/16
      @score9 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s9.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score10 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s10.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score11 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s11.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score12 = FactoryGirl.create(:cds_metric_score, score: 60, company_id: cid, snapshot_id: @s12.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      
      # October - H2/16
      @score13 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s13.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score14 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s14.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score15 = FactoryGirl.create(:cds_metric_score, score: 60, company_id: cid, snapshot_id: @s15.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score16 = FactoryGirl.create(:cds_metric_score, score: 70, company_id: cid, snapshot_id: @s16.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)

      # November - H2/16
      @score17 = FactoryGirl.create(:cds_metric_score, score: 100, company_id: cid, snapshot_id: @s17.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score18 = FactoryGirl.create(:cds_metric_score, score: 500, company_id: cid, snapshot_id: @s18.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score19 = FactoryGirl.create(:cds_metric_score, score: 600, company_id: cid, snapshot_id: @s19.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score20 = FactoryGirl.create(:cds_metric_score, score: 700, company_id: cid, snapshot_id: @s20.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)

      # January - H1/17
      @score21 = FactoryGirl.create(:cds_metric_score, score: 100, company_id: cid, snapshot_id: @s21.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score22 = FactoryGirl.create(:cds_metric_score, score: 500, company_id: cid, snapshot_id: @s22.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score23 = FactoryGirl.create(:cds_metric_score, score: 600, company_id: cid, snapshot_id: @s23.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score24 = FactoryGirl.create(:cds_metric_score, score: 700, company_id: cid, snapshot_id: @s24.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
    end

    describe 'test half years averages' do
      
      before(:all) do
        @res = get_emails_volume_scores(2)
        puts "@res ? #{@res.inspect}"
      end

      it 'should return correct number of averages per intervals' do
        expect(@res.length).to eq(3)
      end

      it 'should return correct interval name' do
        expect(@res[0][:time_period]).to eq('H1/16')
      end

      it 'should return correct average' do
        correct_avg = 25
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

  describe 'test method: get_emails_volume_scores() - test year averages' do
  
    before(:all) do
      cid = 2
      company_metric_id = 6
      emails_scores_algorithm_id = 707

      # Snapshots
      # June - 2015
      @s1 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2015-05-01 18:00:00')
      @s2 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2015-05-08 18:00:00')
      @s3 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2015-05-17 18:00:00')
      @s4 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2015-05-28 18:00:00')
      
      # August - 2015
      @s5 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2015-06-01 18:00:00')
      @s6 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2015-06-08 18:00:00')
      @s7 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2015-06-17 18:00:00')
      @s8 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2015-06-28 18:00:00')
      
      # September - 2016
      @s9 = FactoryGirl.create(:snapshot, company_id: cid, timestamp:  '2016-09-01 18:00:00')
      @s10 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-08 18:00:00')
      @s11 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-17 18:00:00')
      @s12 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-09-28 18:00:00')
      
      # October - 2016
      @s13 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-01 18:00:00')
      @s14 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-08 18:00:00')
      @s15 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-17 18:00:00')
      @s16 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-10-28 18:00:00')

      # November - 2016
      @s17 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-11-01 18:00:00')
      @s18 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-11-08 18:00:00')
      @s19 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-11-17 18:00:00')
      @s20 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2016-11-28 18:00:00')

      # January - 2017
      @s21 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2017-01-01 18:00:00')
      @s22 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2017-01-08 18:00:00')
      @s23 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2017-01-17 18:00:00')
      @s24 = FactoryGirl.create(:snapshot, company_id: cid, timestamp: '2017-01-28 18:00:00')

      # Emails volume scores
      # June - 2015
      @score1 = FactoryGirl.create(:cds_metric_score, score: 10, company_id: cid, snapshot_id: @s1.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score2 = FactoryGirl.create(:cds_metric_score, score: 20, company_id: cid, snapshot_id: @s2.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score3 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s3.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score4 = FactoryGirl.create(:cds_metric_score, score: 100, company_id: cid, snapshot_id: @s4.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)

      # August - 2015
      @score5 = FactoryGirl.create(:cds_metric_score, score: 20, company_id: cid, snapshot_id: @s5.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score6 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s6.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score7 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s7.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score8 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s8.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      
      # September - 2016
      @score9 = FactoryGirl.create(:cds_metric_score, score: 30, company_id: cid, snapshot_id: @s9.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score10 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s10.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score11 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s11.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score12 = FactoryGirl.create(:cds_metric_score, score: 60, company_id: cid, snapshot_id: @s12.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      
      # October - 2016
      @score13 = FactoryGirl.create(:cds_metric_score, score: 40, company_id: cid, snapshot_id: @s13.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score14 = FactoryGirl.create(:cds_metric_score, score: 50, company_id: cid, snapshot_id: @s14.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score15 = FactoryGirl.create(:cds_metric_score, score: 60, company_id: cid, snapshot_id: @s15.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score16 = FactoryGirl.create(:cds_metric_score, score: 70, company_id: cid, snapshot_id: @s16.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)

      # November - 2016
      @score17 = FactoryGirl.create(:cds_metric_score, score: 100, company_id: cid, snapshot_id: @s17.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score18 = FactoryGirl.create(:cds_metric_score, score: 500, company_id: cid, snapshot_id: @s18.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score19 = FactoryGirl.create(:cds_metric_score, score: 600, company_id: cid, snapshot_id: @s19.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score20 = FactoryGirl.create(:cds_metric_score, score: 700, company_id: cid, snapshot_id: @s20.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)

      # January - 2017
      @score21 = FactoryGirl.create(:cds_metric_score, score: 100, company_id: cid, snapshot_id: @s21.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score22 = FactoryGirl.create(:cds_metric_score, score: 500, company_id: cid, snapshot_id: @s22.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score23 = FactoryGirl.create(:cds_metric_score, score: 600, company_id: cid, snapshot_id: @s23.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
      @score24 = FactoryGirl.create(:cds_metric_score, score: 700, company_id: cid, snapshot_id: @s24.id, employee_id: -1, company_metric_id: company_metric_id, algorithm_id: emails_scores_algorithm_id)
    end

    describe 'test half years averages' do
      
      before(:all) do
        @res = get_emails_volume_scores(3)
        puts "@res ? #{@res.inspect}"
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
end