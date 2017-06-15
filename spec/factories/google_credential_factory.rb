FactoryGirl.define do
  factory :google_credential do
    company_id 1
    refresh_token SecureRandom.hex
    access_token SecureRandom.hex
  end
end
