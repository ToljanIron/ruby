require 'spec_helper'

describe Job, type: :model do
  p = nil
  before do
    EventType.create!(id: 19, name: 'JOB')
    p = Job.create!(
      company_id: 1,
      domain_id: 'test_proc',
      module_name: 'spec',
      job_type: 'testing'
    )
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  it 'should go through an entire flow' do
    ## Add two stages
    stage1 = p.create_stage('stage1', order: 1, value: 8)
    expect( stage1.stage_type ).to eq('testing')
    expect( stage1.job_id ).to eq(p.id)
    expect( stage1.value ).to eq('8')
    expect( stage1.stage_order ).to eq(1)

    stage2 = p.create_stage('stage2', order: 2)
    expect( stage2.value ).to eq('1')

    ## Start job
    p.start
    expect( p.status ).to eq('in_progress')
    expect( EventLog.count ).to eq(1)

    ## work on first stage
    s = p.get_next_stage
    expect( s[:domain_id] ).to eq( stage1[:domain_id])
    s.finish_successfully(7)
    expect( s[:status]).to eq('done')
    expect( EventLog.count ).to eq(2)

    ## fail at second stage
    s = p.get_next_stage
    expect( s[:domain_id] ).to eq( stage2[:domain_id])
    s.finish_with_error('Job failed')
    p.finish_with_error('Stage2 failed')
    expect( p[:status] ).to eq('wait_for_retry')
    expect( s[:status] ).to eq('error')
    expect( p[:error_message] ).to eq('Stage2 failed')
    expect( EventLog.count ).to eq(4)

    ## retry second stage
    p.retry
    expect( p.status ).to eq('in_progress')

    ## finish second stage with success
    s = p.get_next_stage
    expect( s[:domain_id] ).to eq( stage2[:domain_id])
    s.finish_successfully(5)
    expect( EventLog.count ).to eq(6)

    ## finish job with success
    p.finish_successfully
    expect( s[:status]).to eq('done')
    expect( p[:status] ).to eq('done')
    expect( EventLog.count ).to eq(7)
  end

  describe 'update_progress' do
    it 'should update progress' do
      p.update_progress('First step', 55.33 )
      expect(p.name_of_step).to eq('First step')
      expect(p.percent_complete.to_s.to_f).to eq(55.3)
    end

    it 'should update progress without percent_complete' do
      p.create_stage('s1').update(status: :done)
      p.create_stage('s2').update(status: :running)
      p.create_stage('s3')
      p.update_progress
      expect(p.percent_complete).to eq(33.3)
    end

    context 'with 9 stages and 3 stage_types' do
      before do
        p.create_stage('t1s1', stage_type: 't1')
        p.create_stage('t1s2', stage_type: 't1')
        p.create_stage('t1s3', stage_type: 't1')
        p.create_stage('t2s1', stage_type: 't2')
        p.create_stage('t2s2', stage_type: 't2')
        p.create_stage('t2s3', stage_type: 't2')
        p.create_stage('t3s1', stage_type: 't3')
        p.create_stage('t3s2', stage_type: 't3')
        p.create_stage('t3s3', stage_type: 't3')
      end

      it 'with all stages ready' do
        p.update_progress
        expect(p.percent_complete).to eq(0)
      end

      it 'with some stages done' do
        JobStage.where(stage_type: 't1').update_all(status: 'done')
        p.update_progress
        expect(p.percent_complete).to eq(33.3)

        JobStage.where(domain_id: 't2s1').update_all(status: 'done')
        p.update_progress
        expect(p.percent_complete).to eq(44.4)

        JobStage.where(domain_id: 't2s2').update_all(status: 'done')
        p.update_progress
        expect(p.percent_complete.to_s.to_f).to eq(55.5)
      end

      it 'with one of the stages running' do
        JobStage.where(stage_type: 't1').update_all(status: 'done')
        JobStage.where(stage_type: 't2').update_all(status: 'done')
        JobStage.where(domain_id: 't3s1').update_all(status: 'running')
        p.update_progress
        expect(p.percent_complete.to_s.to_f).to eq(66.6)

        JobStage.where(domain_id: 't3s1').last.finish_successfully
        p = Job.last
        expect(p.percent_complete.to_s.to_f).to eq(77.7)
      end
    end
  end
end
