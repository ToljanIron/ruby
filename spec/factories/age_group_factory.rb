FactoryGirl.define do
  factory :age_group do
    sequence(:name) { |n| "age_group_#{n}" }
  end
end
