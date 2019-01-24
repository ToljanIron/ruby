require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/create_analyze_historical_data_helper.rb'

JOB_STAGE_ORDER_COLLECTION      = 1
JOB_STAGE_ORDER_CREATE_SNAPSHOT = 2
JOB_STAGE_ORDER_PRECALCULATRE   = 1000

describe AnalyzeHistoricalDataHelper, type:  :helper do
  cid = 1
  before do
    FactoryBot.create(:company, id: cid)
    FactoryBot.create(:snapshot, timestamp: 4.months.ago)
    NetworkName.create!(company_id: cid, name: 'Communication Flow')
    PushProc.create!(company_id: cid)

    ## Create metrics and algorithms
    AlgorithmType.find_or_create_by!(id: 1, name: 'measure')
    Algorithm.find_or_create_by!(id: 700, name: 'spammers_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
    spammers_id = MetricName.find_or_create_by!(name: 'Spammers', company_id: 1).id
    CompanyMetric.find_or_create_by!(metric_id: spammers_id, network_id: -1, company_id: 1, algorithm_id: 700, algorithm_type_id: 1)
    Algorithm.find_or_create_by!(id: 701, name: 'blitzed_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
    blitzed_id  = MetricName.find_or_create_by!(name: 'Blitzed', company_id: 1).id
    CompanyMetric.find_or_create_by!(metric_id: blitzed_id, network_id: -1, company_id: 1, algorithm_id: 701, algorithm_type_id: 1)

    ## Create groups and employees
    FactoryBot.create(:group)
    FactoryBot.create(:group)
    Group.find(1).update(hierarchy_size: 3, nsleft: 1, nsright: 4)
    Group.find(2).update(parent_group_id: 1, hierarchy_size: 2, nsleft: 2, nsright: 3)

    FactoryBot.create(:employee, email: 'emp1@acme.com',group_id: 1)
    FactoryBot.create(:employee, email: 'emp2@acme.com',group_id: 2)
    FactoryBot.create(:employee, email: 'emp3@acme.com',group_id: 2)

    ## Create raw entries
    dates = [Time.now, 1.month.ago, 2.month.ago]
    dates.each do |date|
      FactoryBot.create(:raw_data_entry, from: 'emp1@acme.com', to: ['emp2@acme.com'], date: date)
      FactoryBot.create(:raw_data_entry, from: 'emp1@acme.com', to: ['emp3@acme.com'], date: date)
      FactoryBot.create(:raw_data_entry, from: 'emp2@acme.com', to: ['emp1@acme.com'], date: date)
    end
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
  end

  describe 'e2e data for 3 months' do

    it 'should work' do
      AnalyzeHistoricalDataHelper.run(cid)
      expect( RawDataEntry.where(processed: false).count ).to eq(0)
      expect( Snapshot.count ).to eq(4)
      expect( CdsMetricScore.count ).to be > 0
      pp = PushProc.last
      expect( pp.state ).to eq('done')
      expect( pp.num_snapshots ).to eq(9)
      expect( pp.num_snapshots_created ).to eq(3)
      expect( pp.num_snapshots_processed ).to eq(3)
    end

    it 'should not fail if there are no rdes' do
      RawDataEntry.delete_all
      expect { AnalyzeHistoricalDataHelper.run(cid) }.not_to raise_error
      expect( PushProc.last.state ).to eq('done')
    end
  end

  describe 'Test an entire job e2e' do
    job = nil
    before :each do
      job = Job.create!(
        company_id: cid,
        domain_id: 'o365-collection-historical-data-timestamp',
        module_name: 'o365_collector',
        job_type: 'collection')
      js = job.create_stage("get-user-emails-and-meetings-1",
                        value: 'some users here',
                        order: JOB_STAGE_ORDER_COLLECTION,
                        stage_type: 'collection')
      js.finish_successfully
      job.create_stage('collect-history-create-snapshot',
                        value: 'Create snapshot',
                        order: JOB_STAGE_ORDER_CREATE_SNAPSHOT,
                        stage_type: 'create_snapshot')
      job.create_stage('collect-history-precalculate',
                        value: 'Create snapshot',
                        order: JOB_STAGE_ORDER_PRECALCULATRE,
                        stage_type: 'precalculate')
      job.start
    end

    it 'a full cycle should work' do
      AnalyzeHistoricalDataHelper.run(cid)
      validate_job
    end

    context 'a stage throws an exception' do
      it 'should mark job as wait_for_retry' do
        allow(AnalyzeHistoricalDataHelper).to receive(:run_precalculate_stage).and_raise('Unexpected error')
        begin
          AnalyzeHistoricalDataHelper.run(cid)
        rescue
          puts 'Exception was thrown'
        end
        expect( Job.last.status ).to eq('wait_for_retry')
      end
    end

    context 'a stage throws 3 excpetions' do
      it 'should mark job as error' do
        allow(AnalyzeHistoricalDataHelper).to receive(:run_precalculate_stage).and_raise('Unexpected error')
        (0..2).each do
          begin
            AnalyzeHistoricalDataHelper.run(cid)
          rescue
            puts 'Exception was thrown'
          end
        end
        expect( Job.last.status ).to eq('error')
      end
    end

    describe 'Resuming uncompleted jobs' do
      context 'job is restarted after some snapshots where already created' do
        before do
          create_snapshot_stages(cid, job, 4)
          AnalyzeHistoricalDataHelper.run(cid)
        end

        it 'should create all stages and finish the job' do
          validate_job
        end
      end

      context 'job is restarted after all snapshots where already created' do
        before do
          create_snapshot_stages(cid, job, 10)
          AnalyzeHistoricalDataHelper.run(cid)
        end

        it 'should finish the job' do
          validate_job
        end
      end

      context 'job is restarted after some snapshots where already processed' do
        before do
          create_snapshot_stages(cid, job, 10, 8)
          AnalyzeHistoricalDataHelper.run(cid)
        end

        it 'should finish the job' do
          validate_job
        end
      end

      context 'job is restarted after all snapshots where already processed' do
        before do
          create_snapshot_stages(cid, job, 10, 11)
          AnalyzeHistoricalDataHelper.run(cid)
        end

        it 'should finish the job' do
          validate_job
        end
      end

      context 'job is restarted after some snapshots where calculated' do
        before do
          create_snapshot_stages(cid, job, 10, 11)
          first_precalc_stage = JobStage.where(stage_type: 'precalculate')
                                        .where("stage_order > 1000")
                                        .order(:stage_order)
                                        .first
          AnalyzeHistoricalDataHelper.run_precalculate_stage(job,
                                                             first_precalc_stage,
                                                             first_precalc_stage.sid,
                                                             cid)
          AnalyzeHistoricalDataHelper.run(cid)
        end

        it 'should finish the job' do
          validate_job
        end
      end
    end
  end
end

###############################################################################
# Make sure that a job has ended well
###############################################################################
def validate_job
  # The job should be in done state
  expect( Job.last.status ).to eq('done')

  # All stages should be done
  expect( JobStage.where.not(status: :done).count ).to eq(0)

  # There should be more create_snapshot stages than precalc ones
  csnp = JobStage.where(stage_type: 'create_snapshot').count
  prec = JobStage.where(stage_type: 'precalculate').count
  expect( csnp ).to be > prec

  # Each precalc value should correspond to a valid snashot
  precs = JobStage.where("domain_id like 'collect-history-precalculate-%'")
  precs.each do |pr|
    sid = pr.value
    expect( Snapshot.find_by(id: sid) ).not_to be_nil
  end

  # Check number of snapshots
  expect( Snapshot.count ).to be(4)

  # Number of calculations should be divisible by 3 because there were 3
  # snapshots
  expect( CdsMetricScore.count % 3 ).to be(0)
end

###############################################################################
# Create some of the stages
# If a stage is marked as done, then we also need to create the adjoining
# precalculate stage
###############################################################################
def create_snapshot_stages(cid, job, num_stages, num_done=0)
  mind = RawDataEntry.select('MIN(date)').where(company_id: 1, processed: false)[0][:min]
  (0..num_stages).each do |i|
    date_str = (mind + i.weeks).to_s
    order = JOB_STAGE_ORDER_CREATE_SNAPSHOT + i + 1
    js = job.create_stage("collect-history-create-snapshot-#{i}",
                         stage_type: 'create_snapshot',
                         order: order,
                         value: date_str)
    if (i <= num_done - 1)
      snapshot = CreateSnapshotHelper::create_company_snapshot_by_weeks(cid, date_str, true)
      if snapshot.nil?
        js.finish_successfully('Nothing to do')
        next
      end
      sid = snapshot.id
      job.create_stage("collect-history-precalculate-#{sid}",
                       stage_type: 'precalculate',
                       value: sid,
                       order: 1000 + i)
      js.finish_successfully('Snapshot created')
    end
  end
end
