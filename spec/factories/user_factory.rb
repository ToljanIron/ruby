FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@domain.com" }
    password { 'A!a123' }
    password_confirmation { 'A!a123' }
  end
end
