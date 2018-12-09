require 'spec_helper'

describe JobsHelper, type: :helper do
  ## If we don't add this line, the tests will run the
  ## jobs automatically.
  before do
    Delayed::Worker.delay_jobs = true
    Company.create!(id: 1, name: 'Comp', setup_state: :ready)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  it 'should create hourly jobs' do
    JobsHelper.schedule_hourly_job(TestJob, 'testqueue')
    expect(Delayed::Job.count).to eq(24)
  end

  it 'should not create duplicate hourly jobs' do
    JobsHelper.schedule_hourly_job(TestJob, 'testqueue')
    JobsHelper.schedule_hourly_job(TestJob, 'testqueue')
    expect(Delayed::Job.count).to eq(24)
  end

  it 'should not create tests for occupied timeslots' do
    Delayed::Job.enqueue(TestJob.new, queue: 'testqueue', run_at: 1.hours.from_now)
    Delayed::Job.enqueue(TestJob.new, queue: 'testqueue', run_at: 11.hours.from_now)

    JobsHelper.schedule_hourly_job(TestJob, 'testqueue')
    expect(Delayed::Job.count).to eq(24)
  end

  ## We run these tests with respect to a specific time. The dates we use are
  ## the week of 2018-08-26 (Sunday) to 2018-09-01 (Saturday).
  ## We stub Time.now for this purpose
  describe 'weekly tests' do
    it 'If there is no job and day of week to schedule is smaller than day of week today' do
      ## Set date to a Tuesday job should run on Mondays
      Date.stub(:today) { DateTime.new(2018,8,28) }

      JobsHelper.schedule_weekly_job(TestJob, 'testqueue', 1)

      expect(Delayed::Job.count).to eq(1)
      expect(Delayed::Job.first.run_at).to eq( DateTime.new(2018,9,3) )
    end

    it 'If there is job and day of week to schedule is smaller than day of week today' do
      ## Set date to a Tuesday job should run on Mondays
      Date.stub(:today) { DateTime.new(2018,8,28) }
      Delayed::Job.enqueue(TestJob.new, queue: 'testqueue', run_at: DateTime.new(2018,9,3))

      JobsHelper.schedule_weekly_job(TestJob, 'testqueue', 1)

      expect(Delayed::Job.count).to eq(1)
      expect(Delayed::Job.first.run_at).to eq( DateTime.new(2018,9,3) )
    end

    it 'If there is job and day of week to schedule is bigger than day of week today' do
      ## Set date to a Tuesday job should run on Mondays
      Date.stub(:today) { DateTime.new(2018,8,28) }
      Delayed::Job.enqueue(TestJob.new, queue: 'testqueue', run_at: DateTime.new(2018,8,30))

      JobsHelper.schedule_weekly_job(TestJob, 'testqueue', 4)

      expect(Delayed::Job.count).to eq(1)
      expect(Delayed::Job.last.run_at).to eq( DateTime.new(2018,8,30) )
    end

    it 'If there is no job and day of week to schedule is bigger than day of week today' do
      ## Set date to a Tuesday job should run on Mondays
      Date.stub(:today) { DateTime.new(2018,8,28) }
      Delayed::Job.enqueue(TestJob.new, queue: 'testqueue', run_at: DateTime.new(2018,8,23))

      JobsHelper.schedule_weekly_job(TestJob, 'testqueue', 4)

      expect(Delayed::Job.count).to eq(2)
      expect(Delayed::Job.last.run_at).to eq( DateTime.new(2018,8,30) )
    end
  end

  describe 'Daily job' do
    it 'should schedule a new job if there is no job today' do
      JobsHelper.schedule_daily_job(TestJob, 'testqueue', 15)
      expect(Delayed::Job.count).to eq(1)
      expect(Delayed::Job.last.run_at).to eq( 1.day.from_now.at_beginning_of_day + 15.hours )
    end

    it 'should not schedule a new job if there is a job today' do
      Delayed::Job.enqueue(TestJob.new,
                           queue: 'testqueue',
                           run_at: 1.day.from_now)
      JobsHelper.schedule_daily_job(TestJob, 'testqueue', 15)
      expect(Delayed::Job.count).to eq(1)
    end
  end

  describe 'schedule_delayed_jobs' do
    it 'should schedule 1 hourely job and 1 daily job' do
      JobsHelper.stub(:get_jobs_list) {
        [
          {job: CollectorJob, interval: 'hourly', interval_offset: 0, queue: 'collqueue'},
          {job: TestJob,      interval: 'daily',  interval_offset: 3, queue: 'testqueue'},
        ]
      }
      JobsHelper.schedule_delayed_jobs

      jobs = Delayed::Job.where(run_at: 1.hour.ago .. 24.hours.from_now)
      expect(jobs.count).to eq(25)
      expect(Delayed::Job.count).to eq(25)
      weekly_job = Delayed::Job.where("handler like '%TestJob%'")
      expect(weekly_job.count).to eq(1)
    end
  end
end
