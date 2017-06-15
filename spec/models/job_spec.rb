require 'spec_helper'
require 'rake'

describe Job, type: :model do
  before do
    Company.create(name: 'Test Company')
    @job = Job.make_me_a_job
    Rake::Task['db:test_job_task'].reenable
    EventType.create(name: 'GENERAL_EVENT')
    EventType.create(name: 'JOB_STARTED')
    EventType.create(name: 'JOB_DONE')
    EventType.create(name: 'JOB_KILLED_ERR_DID_NOT_RUN')
    EventType.create(name: 'JOB_KILLED_ERR_DID_NOT_FINISH')
    EventType.create(name: 'JOB_ARCHIVED')
    EventType.create(name: 'JOB_FAIL')
    EventType.create(name: 'JOB_ARCHIVED')
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @job }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:company_id) }
  it { is_expected.to respond_to(:reoccurrence_id) }

  describe ', jobs operations' do
    it ', should not be scheduled yet' do
      @job.delete
      jobs = Job.get_jobs_to_be_run(10)
      expect(jobs.length).to be == 0
      custom_job = Job.make_me_a_job
      puts custom_job.next_run
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      jobs = Job.get_jobs_to_be_run(10, 10.minutes.ago)
      expect(jobs.length).to be == 0
      jobs = Job.get_jobs_to_be_run(10, 10.minutes.since)
      expect(jobs.length).to be == 1
    end

    it ', should be pending' do
      custom_job = Job.make_me_a_job
      custom_job.create_job
      expect(custom_job.job_status).to be == JobsQueue::PENDING
    end

    it ', should be running' do
      @job.delete
      custom_job = Job.make_me_a_job
      expect(Job.get_jobs_to_be_run(10, 10.minutes.since).length).to be == 1
      custom_job.create_job
      expect(Job.get_jobs_to_be_run(10, 10.minutes.since).length).to be == 0
      expect(Job.get_jobs_to_be_run(10, 10.hours.since).length).to be == 1

      et_id = EventType.find_by(name: 'GENERAL_EVENT')
      log = EventLog.where(job_id: custom_job.id, event_type_id: et_id).first
      expect(log).to be_nil

      custom_job.start_job
      et_id = EventType.find_by(name: 'JOB_STARTED')
      # need to add job id to event log
      log = EventLog.where(event_type_id: et_id).first

      expect(custom_job.job_status).to be == JobsQueue::RUNNING
      expect(Job.get_jobs_queues_with_status(JobsQueue::RUNNING, 10).length).to be == 1
      expect(Job.get_jobs_queues_with_status(JobsQueue::PENDING, 10).length).to be == 0
      expect(Job.get_jobs_queues_with_status(JobsQueue::ENDED, 10).length).to be == 0
    end

    it ', should be ended' do
      custom_job = Job.make_me_a_job
      custom_job.create_job

      et_id = EventType.find_by(name: 'GENERAL_EVENT')
      log = EventLog.where(job_id: custom_job.id, event_type_id: et_id).first
      expect(log).to be_nil

      custom_job.end_job
      et_id = EventType.find_by(name: 'JOB_DONE')
      # need to add job id to event log!!
      log = EventLog.where(event_type_id: et_id).first

      expect(custom_job.job_status).to be == JobsQueue::ENDED
      expect(Job.get_jobs_queues_with_status(JobsQueue::ENDED, 10)[0].length).to be == 1
      expect(Job.get_jobs_queues_with_status(JobsQueue::PENDING, 10).length).to be == 0
      expect(Job.get_jobs_queues_with_status(JobsQueue::RUNNING, 10).length).to be == 0
    end

    it ', should be kiiled becuase it didnt run' do
      custom_job = Job.make_me_a_job
      custom_job.create_job

      et_id = EventType.find_by(name: 'GENERAL_EVENT')
      log = EventLog.where(job_id: custom_job.id, event_type_id: et_id).first
      expect(log).to be_nil
      custom_job.terminate_job_with_error_status  JobsQueue::KILLED_ERROR_DID_NOT_RUN

      et_id = EventType.find_by(name: 'JOB_FAIL')
      log = EventLog.where(event_type_id: et_id, job_id: custom_job.id).first

      expect(custom_job.job_status).to be == JobsQueue::KILLED_ERROR_DID_NOT_RUN
      expect { custom_job.create_job }.not_to raise_error
      expect(Job.get_jobs_queues_with_status(JobsQueue::ENDED, 10).length).to be == 0
      expect(Job.get_jobs_queues_with_status(JobsQueue::PENDING, 10)[0].length).to be == 1
      expect(Job.get_jobs_queues_with_status(JobsQueue::RUNNING, 10).length).to be == 0
      expect(Job.get_jobs_queues_with_status(JobsQueue::KILLED_ERROR_DID_NOT_RUN, 10).length).to be == 1
    end

    it ', should be kiiled becuase it didnt finish in time' do
      custom_job = Job.make_me_a_job
      custom_job.create_job
      custom_job.terminate_job_with_error_status  JobsQueue::KILLED_ERROR_DID_NOT_FINISH_IN_TIME
      expect(custom_job.job_status).to be == JobsQueue::KILLED_ERROR_DID_NOT_FINISH_IN_TIME
      expect { custom_job.create_job }.not_to raise_error
    end

    it ', should fail becuase there is a job in progress' do
      custom_job = Job.make_me_a_job
      custom_job.create_job
      expect { custom_job.create_job }.to raise_error
    end

    it ', should not fail becuase there is a job that had ended but not archived' do
      custom_job = Job.make_me_a_job
      custom_job.create_job
      custom_job.start_job
      custom_job.end_job
      expect { custom_job.create_job }.not_to raise_error
    end

    it ', should fail becuase there is no job in progress' do
      custom_job = Job.make_me_a_job
      expect { custom_job.start_job }.to raise_error
    end

    it ', should be archived' do
      custom_job = Job.make_me_a_job
      custom_job.create_job
      custom_job.end_job
      expect(custom_job.job_status).to be == JobsQueue::ENDED
      expect(custom_job.jobs_archives.length).to be == 0
      custom_job.create_job
      custom_job.archive_jobs(Job::ARCHIVE_ALL)
      custom_job.reload
      expect(custom_job.jobs_archives.length).to be == 2
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
    end

    it ', should be archived only old' do
      custom_job = Job.make_me_a_job
      custom_job.create_job
      custom_job.end_job
      expect(custom_job.job_status).to be == JobsQueue::ENDED
      expect(custom_job.jobs_archives.length).to be == 0
      custom_job.create_job
      expect(custom_job.job_status).to be == JobsQueue::PENDING
      custom_job.archive_jobs(Job::ARCHIVE_OLD)
      custom_job.reload
      expect(custom_job.jobs_archives.length).to be == 1
      expect(custom_job.job_status).to be == JobsQueue::PENDING
    end

    it ', should be archived only active' do
      custom_job = Job.make_me_a_job
      custom_job.create_job
      custom_job.end_job
      expect(custom_job.job_status).to be == JobsQueue::ENDED
      expect(custom_job.jobs_archives.length).to be == 0
      custom_job.create_job
      expect(custom_job.job_status).to be == JobsQueue::PENDING
      custom_job.archive_jobs(Job::ARCHIVE_ACTIVE)
      custom_job.reload
      expect(custom_job.jobs_archives.length).to be == 1
      expect(custom_job.job_status).to be == JobsQueue::ENDED
    end

    it ', should be ready to run' do
      custom_job = Job.make_me_a_job
      custom_job.next_run = 100.minutes.ago
      expect(custom_job.should_run?).to be == true
    end

    it ', should not be ready to run' do
      custom_job = Job.make_me_a_job
      custom_job.next_run = 100.minutes.since
      expect(custom_job.should_run?).to be == false
    end

    it ', should have ended be true' do
      @job.delete
      custom_job = Job.make_me_a_job
      custom_job.create_job
      offset =  custom_job.reoccurrence.fail_after_by_minutes + 10
      now = offset.minutes.since
      custom_job.mock_now = now
      expect(custom_job.job_should_have_ended?).to be == true
      jobs = Job.get_jobs_queues_that_should_have_ended(10, now)
      expect(custom_job.current_job_queue.id == jobs.first.id).to be == true
    end

    it ', should have ended be false' do
      custom_job = Job.make_me_a_job
      custom_job.create_job
      now = DateTime.now + custom_job.reoccurrence.fail_after_by_minutes.minutes - 10.minutes
      custom_job.mock_now = DateTime.now + custom_job.reoccurrence.fail_after_by_minutes.minutes - 10.minutes
      expect(custom_job.job_should_have_ended?).to be == false
      jobs = Job.get_jobs_queues_that_should_have_ended(10, now)
      expect(jobs.length).to be == 0
    end

    it ', should run a job task' do
      custom_job = Job.make_me_a_job
      custom_job.type_number = Job::SYSTEM_JOB
      custom_job.name = 'db:test_job_task'
      custom_job.save!
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      custom_job.create_job
      custom_job.reload
      expect(custom_job.job_status).to be == JobsQueue::ENDED
    end

    xit ', should run a job and its dependencies' do
      custom_job = Job.make_me_a_job
      custom_dep = Job.make_me_a_job
      custom_dep.add_as_depeendent_of(custom_job)
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      expect(custom_dep.job_status).to be == JobsQueue::NOT_SCHEDULED
      custom_job.create_job
      expect(custom_job.job_status).to be == JobsQueue::PENDING
      expect(custom_dep.job_status).to be == JobsQueue::NOT_SCHEDULED
      custom_job.end_job
      expect(custom_job.job_status).to be == JobsQueue::ENDED
      expect(custom_dep.job_status).to be == JobsQueue::PENDING
      custom_dep.end_job
      expect(custom_job.job_status).to be == JobsQueue::ENDED
      expect(custom_dep.job_status).to be == JobsQueue::ENDED
    end

    it ', shouldnt run if have constraint active but run if dont have a constraint' do
      custom_job = Job.make_me_a_job
      custom_working = Job.make_me_a_job
      custom_job.add_dont_schedule_constraint_becuase_of custom_working
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      expect(custom_working.job_status).to be == JobsQueue::NOT_SCHEDULED
      custom_working.create_job
      custom_working.start_job
      #expect(custom_job.job_status).to be == JobsQueue::RUNNING
      expect(custom_working.job_status).to be == JobsQueue::RUNNING
      custom_working.end_job
      custom_job.reload
      custom_job.create_job
      expect(custom_job.job_status).to be == JobsQueue::PENDING
    end
  end
end
