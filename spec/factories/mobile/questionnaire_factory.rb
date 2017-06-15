FactoryGirl.define do
  factory :questionnaire do
    sequence(:name) { |n| "questionnaire_#{n}" }
    company_id 1
    sent_date Time.now
  end
end
