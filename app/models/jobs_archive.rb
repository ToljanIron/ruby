class JobsArchive < ActiveRecord::Base
  validates :job_id, presence: true
  validates :status, presence: true

  belongs_to :job

  def self.create_job_archive(job_instance)
    JobsArchive.create(job: job_instance.job, status: job_instance.status)
  end
end
