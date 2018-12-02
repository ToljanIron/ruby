FactoryBot.define do
  factory :scheduled_api_client_task do
    api_client_task_definition_id { 1 }
    status { 'pending' }
    jobs_queue_id { nil }
    expiration_date { Time.now + 1.day }
  end
end
