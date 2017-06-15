require 'spec_helper'

describe JobsQueue, type: :model do
  before do
    Company.create(name: 'Test Company')
    @jobs_queue = JobsQueue.new
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @jobs_queue }

  it { is_expected.to respond_to(:job_id) }
  it { is_expected.to respond_to(:status) }

  describe 'with invalid data should be invalid' do
    it { is_expected.not_to be_valid }
  end

  describe ', utils functions' do
    it ', should be a job queue that is pending' do
      job_instance = JobsQueue.create_job_instance(Job.make_me_a_job)
      expect(job_instance.status).to be == JobsQueue::PENDING
      expect(job_instance.running_or_pending?).to be == true
    end

    it ', should be a job queue that is running' do
      job_instance = JobsQueue.create_job_instance(Job.make_me_a_job)
      job_instance.status = JobsQueue::RUNNING
      expect(job_instance.running_or_pending?).to be == true
    end

    it ', should be a job queue that is not running' do
      job_instance = JobsQueue.create_job_instance(Job.make_me_a_job)
      job_instance.status = JobsQueue::ENDED
      expect(job_instance.running_or_pending?).to be == false
    end
  end
end
