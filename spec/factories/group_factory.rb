FactoryGirl.define do
  factory :group do
    sequence(:name) { |n| "group_#{n}" }
    company_id 1
  end
end
