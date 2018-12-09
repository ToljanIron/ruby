FactoryBot.define do
  factory :job do
    sequence(:name) { |n| "job_#{n}" }
    company_id { 1 }
    next_run { DateTime.now }
  end
end
