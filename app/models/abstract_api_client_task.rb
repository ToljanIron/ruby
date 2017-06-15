class AbstractApiClientTask < ActiveRecord::Base
  self.abstract_class = true

  belongs_to :api_client_task_definition
  belongs_to :jobs_queue

  validates :api_client_task_definition_id, presence: true
  validates :status, presence: true
  # validates :jobs_queue_id, presence: true

  #enum status: [:pending, :running, :error, :done, :priority]
end
