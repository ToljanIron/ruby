FactoryBot.define do
  factory :questionnaire do
    sequence(:name) { |n| "Q_#{n}" }
    company_id { 1 }
    sequence(:snapshot_id) { |n| n }
  end
end
