require 'spec_helper'

describe ReportHelper, type: :helper do
  after do
    DatabaseCleaner.clean_with(:truncation)
  end
  describe 'Regression report' do
    before do
      Company.create!(id: 1, name: 'Acme')
      (1..10).each do |i|
        snapshot_factory_create({id: i})
      end
      Algorithm.create!(id: 1, name: 'algo-1', algorithm_type_id: 5)
      Algorithm.create!(id: 2, name: 'algo-2', algorithm_type_id: 6)
      Group.create!(id: 1, name: 'group-1', company_id: 1)
      create_emps('n', 'acme.com', 5, {gid: 1})
      Group.create!(id: 2, name: 'group-2', company_id: 1)
      create_emps('m', 'acme.com', 6, {gid: 2})
    end

    describe 'query_gauge_data' do
      it 'query_gauge_data sanity' do
        CdsMetricScore.create!(id: 1,  company_id: 1, group_id: 1, snapshot_id: 1, algorithm_id: 1, z_score: 0.1, employee_id: 0, company_metric_id: -1)
        CdsMetricScore.create!(id: 2,  company_id: 1, group_id: 1, snapshot_id: 1, algorithm_id: 1, z_score: 0.2, employee_id: 0, company_metric_id: -1)
        CdsMetricScore.create!(id: 6,  company_id: 1, group_id: 1, snapshot_id: 1, algorithm_id: 2, score:   0.1, employee_id: 0, company_metric_id: -1)
        CdsMetricScore.create!(id: 7,  company_id: 1, group_id: 1, snapshot_id: 1, algorithm_id: 2, score:   0.2, employee_id: 0, company_metric_id: -1)

        res = ReportHelper::query_gauge_data(1)
        expect(res.count).to eq(4)
        expect(res.last['aname']).to eq('algo-2')
      end
    end

    describe 'prepare_regression_report' do
      it 'test with data from db' do
        CdsMetricScore.create!(id: 1,  company_id: 1, group_id: 1, snapshot_id: 1, algorithm_id: 1, z_score: 0.1, employee_id: 0, company_metric_id: -1)
        CdsMetricScore.create!(id: 2,  company_id: 1, group_id: 1, snapshot_id: 1, algorithm_id: 1, z_score: 0.2, employee_id: 0, company_metric_id: -1)
        CdsMetricScore.create!(id: 6,  company_id: 1, group_id: 1, snapshot_id: 1, algorithm_id: 2, z_score: 0.1, employee_id: 0, company_metric_id: -1)
        CdsMetricScore.create!(id: 7,  company_id: 1, group_id: 1, snapshot_id: 1, algorithm_id: 2, z_score: 0.2, employee_id: 0, company_metric_id: -1)
        allow(ReportHelper).to receive(:calculate_regression_slope).and_return( 17 )

        res = ReportHelper::prepare_regression_report(1)
        expect( res.count ).to eq(2)
      end

      it 'test with longer case' do
        allow(ReportHelper).to receive(:query_gauge_data).and_return( query_data )
        allow(ReportHelper).to receive(:calculate_regression_slope).and_return( 17 )
        res = ReportHelper::prepare_regression_report(1)
        expect( res.count ).to eq(4)
        expect( res.first[:aid] ).to eq(1)
        expect( res.first[:slope] ).to eq(17)
        expect( res.first[:orig_score] ).to eq(1.2)
        ap res
      end

      it 'should be able to handle empty result set' do
        allow(ReportHelper).to receive(:query_gauge_data).and_return( [] )
        allow(ReportHelper).to receive(:calculate_regression_slope).and_return( 17 )
        res = ReportHelper::prepare_regression_report(1)
        expect( res ).to eq([])
      end
    end

    describe 'calculate_regression_slop' do
      it 'should be correct' do
        expect(ReportHelper::calculate_regression_slope([1,3,2,4,6])).to eq(1.1)
      end

      it 'should be positive' do
        expect(ReportHelper::calculate_regression_slope([1,3,2])).to be > 0
      end

      it 'should be negative' do
        expect(ReportHelper::calculate_regression_slope([1,0.3,0.2])).to be < 0
      end

      it 'should not handle less then 3 entires' do
        expect(ReportHelper::calculate_regression_slope([1,2])).to be_nil
      end

      it 'should be one for a 45 degree slope' do
        expect(ReportHelper::calculate_regression_slope([1,2,3])).to eq(1)
      end

      it 'should be zero for a flat slope' do
        expect(ReportHelper::calculate_regression_slope([2,2,2])).to eq(0)
      end

      it 'should increase when the slope increases' do
        res1 = ReportHelper::calculate_regression_slope([1, 2, 3])
        res2 = ReportHelper::calculate_regression_slope([1, 2, 4])
        expect(res1).to be < res2
      end
    end

    describe 'prepare_regression_report_in_matrix_format' do
      before do
        CdsMetricScore.create!(company_id:1, employee_id: -1, group_id: 1, snapshot_id: 10, score: 20.0, algorithm_id: 505, company_metric_id: -99)
        CdsMetricScore.create!(company_id:1, employee_id: 0,  group_id: 1, snapshot_id: 10, score: 30.0, algorithm_id: 505, company_metric_id: -99)
        CdsMetricScore.create!(company_id:1, employee_id: 18, group_id: 1, snapshot_id: 10, score: 10.0, algorithm_id: 505, company_metric_id: -99)
        CdsMetricScore.create!(company_id:1, employee_id: 19, group_id: 1, snapshot_id: 10, score: 40.0, algorithm_id: 505, company_metric_id: -99)

        CdsMetricScore.create!(company_id:1, employee_id: -1, group_id: 2, snapshot_id: 10, score: 30.0, algorithm_id: 505, company_metric_id: -99)
        CdsMetricScore.create!(company_id:1, employee_id: 0,  group_id: 2, snapshot_id: 10, score: 50.0, algorithm_id: 505, company_metric_id: -99)
        CdsMetricScore.create!(company_id:1, employee_id: 28, group_id: 2, snapshot_id: 10, score: 10.0, algorithm_id: 505, company_metric_id: -99)
        CdsMetricScore.create!(company_id:1, employee_id: 29, group_id: 2, snapshot_id: 10, score: 10.0, algorithm_id: 505, company_metric_id: -99)
      end

      it 'sanity test' do
        allow(ReportHelper).to receive(:query_gauge_data).and_return( query_data )
        allow(ReportHelper).to receive(:calculate_regression_slope).and_return( 17 )
        res = ReportHelper::prepare_regression_report_in_matrix_format(1)
        puts res
        expect( res.split("\n").count - 1 ).to eq(2)
      end
    end
  end
end

def query_data
  return [
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>1, 'z_score'=>0.1},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>2, 'z_score'=>0.2},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>3, 'z_score'=>0.3},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>4, 'z_score'=>0.5},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>5, 'z_score'=>1.2},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>1, 'z_score'=>0.1},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>2, 'z_score'=>0.2},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>3, 'z_score'=>0.3},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>4, 'z_score'=>0.5},
    {'gid'=>1, 'gname'=>'group-1', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>5, 'z_score'=>1.2},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>1, 'z_score'=>0.1},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>2, 'z_score'=>0.2},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>3, 'z_score'=>0.3},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>4, 'z_score'=>0.5},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>1, 'aname'=>'algo-1', 'sid'=>5, 'z_score'=>1.2},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>1, 'z_score'=>0.1},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>2, 'z_score'=>0.2},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>3, 'z_score'=>0.3},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>4, 'z_score'=>0.5},
    {'gid'=>2, 'gname'=>'group-2', 'aid'=>2, 'aname'=>'algo-2', 'sid'=>5, 'z_score'=>1.2}
  ]
end
