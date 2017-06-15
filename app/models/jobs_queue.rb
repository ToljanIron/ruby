class JobsQueue < ActiveRecord::Base
  validates :job_id, presence: true
  validates :status, presence: true

  belongs_to :job

  NOT_SCHEDULED = -1
  PENDING = 0
  RUNNING = 1
  ENDED = 3
  KILLED_ERROR_DID_NOT_RUN = 4
  KILLED_ERROR_DID_NOT_FINISH_IN_TIME = 5
  FINISHED_WITH_ERROR = 6

  def self.create_job_instance(job)
    JobsQueue.create(job: job, status: PENDING)
  end

  def running_or_pending?
    status == PENDING || status == RUNNING
  end
end
