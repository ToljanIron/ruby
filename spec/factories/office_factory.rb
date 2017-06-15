FactoryGirl.define do
  factory :office do
    sequence(:name) { |n| "office_#{n}" }
    company_id 1
  end
end
