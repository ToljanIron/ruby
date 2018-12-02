FactoryBot.define do
  factory :pin do
    company_id { 1 }
    name { 'pin1' }
    definition { 'nothing' }
    status { :pre_create_pin }
    active { true }
  end
end
