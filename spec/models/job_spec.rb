require 'spec_helper'

describe Job, type: :model do
  before :all do
    EventType.create!(id: 19, name: 'JOB')
  end

  it 'should go through an entire flow' do

    ## Create a new job
    p = Job.create!(
      company_id: 1,
      domain_id: 'test_proc',
      module_name: 'spec',
      job_type: 'testing'
    )

    ## Add two stages
    stage1 = p.create_stage('stage1', order: 1, value: 8)
    expect( stage1.stage_type ).to eq('testing')
    expect( stage1.job_id ).to eq(p.id)
    expect( stage1.value ).to eq(8)
    expect( stage1.stage_order ).to eq(1)

    stage2 = p.create_stage('stage2', order: 2)
    expect( stage2.value ).to eq(1)

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


end
