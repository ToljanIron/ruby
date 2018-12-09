FactoryBot.define do
  factory :seniority do
    sequence(:name) { |n| "seniority_#{n}" }
  end
end
