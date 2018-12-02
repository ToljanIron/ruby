FactoryBot.define do
  factory :api_client_task_definition do
    sequence(:name) { |n| "task_#{n}" }
    script_path { 'script/path.file' }
  end
end
