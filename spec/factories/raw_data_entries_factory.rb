FactoryBot.define do
  factory :raw_data_entry do
    company_id { 1 }
    sequence(:msg_id) { |n| "asdfasf#{n}" }
    reply_to_msg_id { '43214321' }
    processed { false }
    sequence(:from) { |n| "from#{n}@email.com" }
    sequence(:to) { |n| "{to#{n}@email.com}" }
    cc { '' }
    bcc { '' }
    fwd { true }
    subject { SecureRandom.hex(10) }
  end
end
