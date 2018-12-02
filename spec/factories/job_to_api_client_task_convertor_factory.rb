FactoryBot.define do
  factory :job_to_api_client_task_convertor  do
    sequence(:name) { |n| "job_to_api_client_task_convertor #{n}" }
  end
end
