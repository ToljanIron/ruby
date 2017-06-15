FactoryGirl.define do
  factory :domain, class: Domain do
    sequence(:id) { |n| n }
    company_id 1
    sequence(:domain) { |n| "domain#{n}.com" }
  end
end
