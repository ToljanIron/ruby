FactoryBot.define do
  factory :meeting do
    company_id { 1 }
    subject { 'planning SA' }
    start_time { 2.days.ago }
  end
end
