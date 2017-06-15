require 'spec_helper'
require 'rake'

describe 'create_scheduled_tasks' do
  ALGO_NAME = 'some_algo'
  def create_jobs
    Reoccurrence.create_new_occurrence(Reoccurrence::HOUR_MINUTES, Reoccurrence::HOUR_MINUTES)
    c = Company.create(name: 'Test')
    factory_params = { reoccurrence_id: Reoccurrence.first.id, type_number: Job::CLIENT_JOB, company_id:  c.id }
    @job, @job2 = FactoryGirl.create_list(:job, 2, factory_params)
  end

  def create_convertor
    factory_params = { job_id: @job.id, algorithm_name: ALGO_NAME }
    c = FactoryGirl.create(:job_to_api_client_task_convertor, factory_params)
    @job.update(job_to_api_client_task_convertor: c)
    @job2.update(job_to_api_client_task_convertor: c)
  end

  def create_jobs_queue
    factory_params = { job_id: @job.id, status: 'pending' }
    FactoryGirl.create(:jobs_queue, factory_params)
    factory_params = { job_id: @job2.id, status: 'pending' }
    FactoryGirl.create(:jobs_queue, factory_params)
  end

  subject { Rake::Task['db:create_scheduled_tasks'] }

  before do
    Rake::Task['db:seed:event_types'].reenable
    Rake::Task['db:seed:event_types'].invoke
    create_jobs
    create_convertor
    create_jobs_queue
    subject.reenable
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'when there is a jobs_queue pending' do
    it 'should call the job convertion algorithm' do
      algo_called = nil
      expect(ConvertionAlgorithmsHelper).to receive(ALGO_NAME.to_sym).with(anything).twice { algo_called = true }
      subject.invoke
      expect(algo_called).to be true
    end
    it 'should change jobs_queue status from pending to running' do
      expect(ConvertionAlgorithmsHelper).to receive(ALGO_NAME.to_sym).with(anything).twice
      subject.invoke
      JobsQueue.all.each do |jq|
        expect(jq.status).to eq JobsQueue::RUNNING
      end
    end
    it 'should ignore jobs_queue that are not pending' do
      JobsQueue.first.update(status: JobsQueue::RUNNING)
      expect(ConvertionAlgorithmsHelper).to receive(ALGO_NAME.to_sym).with(anything)
      subject.invoke
      expect(JobsQueue.second.status).to eq JobsQueue::RUNNING
    end
  end
end
