include ConvertionAlgorithmsHelper
class JobToApiClientTaskConvertor < ActiveRecord::Base
  belongs_to :job

  validates :job_id, presence: true
  validates :algorithm_name, presence: true

  def self.create_covertor(job_id, algorithm_name, name = nil)
    # TODO: check if job is valid
    return create(job_id: job_id, algorithm_name: algorithm_name, name: name)
  end

  def convert(args = nil)
    ActiveRecord::Base.transaction do
      ConvertionAlgorithmsHelper.send(algorithm_name, args)
    end
  end
end
