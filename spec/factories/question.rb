FactoryGirl.define do
  factory :question do
    company_id 1
    sequence(:title) { |n| "A Title #{n}" }
    sequence(:body) { |n| "A body #{n}" }
    sequence(:order) { |n| n }
    is_funnel_question false
  end
end
