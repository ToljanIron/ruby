require 'spec_helper'
require 'rake'

describe JobsHelper, type: :helper do
  include JobsHelper
  before do
    Company.create(name: 'Test Company')
    Rake::Task['db:test_job_task'].reenable
    Rake::Task['db:seed:event_types'].reenable
    Rake::Task['db:seed:event_types'].invoke
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe ', jobs helper operations' do
    it ', should schedule_new_jobs' do
      custom_job = Job.make_me_a_job
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      schedule_new_jobs
      custom_job.reload
      expect(custom_job.job_status).to be == JobsQueue::PENDING
    end

    it ', should schedule_new_system_jobs' do
      custom_job = Job.make_me_a_job
      custom_job.type_number = Job::SYSTEM_JOB
      custom_job.name = 'db:test_job_task'
      custom_job.save!
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      schedule_new_jobs
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      custom_job.reload
      schedule_new_system_jobs
      expect(custom_job.job_status).to be == JobsQueue::ENDED
    end

    it ', archive old jobs' do
      custom_job = Job.make_me_a_job
      custom_job2 = Job.make_me_a_job
      custom_job.create_job
      custom_job.end_job
      custom_job2.create_job
      custom_job2.end_job
      custom_job2.create_job
      custom_job2.end_job
      custom_job.create_job
      custom_job2.create_job
      archive_jobs
      custom_job.reload
      custom_job2.reload
      #expect(custom_job.jobs_archives.length).to be == 1
      expect(custom_job.job_status).to be == JobsQueue::PENDING
      archive_jobs_that_should_have_ended
      #expect(custom_job2.jobs_archives.length).to be == 2
      expect(custom_job2.job_status).to be == JobsQueue::PENDING
      now = DateTime.now + custom_job2.reoccurrence.fail_after_by_minutes.minutes + 10.minutes
      archive_jobs_that_should_have_ended(now)
      custom_job2.reload
      #expect(custom_job2.jobs_archives.length).to be == 3
      expect(custom_job2.job_status).to be == JobsQueue::NOT_SCHEDULED
    end

    it ', should start a job' do
      old_size = Job.count
      custom_job = Job.make_me_a_job
      expect(Job.count - 1).to eq(old_size)

      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      custom_job.create_job
      expect(custom_job.job_status).to be == JobsQueue::PENDING
      start_job(custom_job.id)
      custom_job.reload
      expect(custom_job.job_status).to be == JobsQueue::RUNNING
    end

    it ', should end a job with error' do
      old_size = Job.count
      custom_job = Job.make_me_a_job
      expect(Job.count - 1).to eq(old_size)
      
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      custom_job.create_job
      expect(custom_job.job_status).to be == JobsQueue::PENDING
      start_job(custom_job.id)
      finish_job(custom_job.id)
      custom_job.reload
      expect(custom_job.job_status).to be == JobsQueue::ENDED
    end

    it ', should end a job with error' do
      custom_job = Job.make_me_a_job
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      custom_job.create_job
      expect(custom_job.job_status).to be == JobsQueue::PENDING
      start_job(custom_job.id)
      finish_job_with_error(custom_job.id)
      custom_job.reload
      expect(custom_job.job_status).to be == JobsQueue::FINISHED_WITH_ERROR
    end

    it ', should schedule new jobs only, with no dependencies' do
      custom_job = Job.make_me_a_job
      custom_dep = Job.make_me_a_job
      custom_dep.add_as_depeendent_of(custom_job)
      expect(custom_job.job_status).to be == JobsQueue::NOT_SCHEDULED
      expect(custom_dep.job_status).to be == JobsQueue::NOT_SCHEDULED
      schedule_new_jobs
      custom_job.reload
      custom_dep.reload
      expect(custom_dep.job_status).to be == JobsQueue::NOT_SCHEDULED
    end
  end
end
