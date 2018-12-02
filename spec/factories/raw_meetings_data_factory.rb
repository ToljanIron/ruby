FactoryBot.define do
  factory :raw_meetings_data do
    company_id { 1 }
    processed { false }
    subject { 'planning SA' }
    location { 'Lobby' }
    duration_in_minutes { '1:30' }
    attendees { '{email1@company.com,email2@company.com,email3@company.com}' }
    start_time { 2.days.ago }
  end
end
