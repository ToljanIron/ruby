FactoryGirl.define do
  factory :questionnaire_question do
    company_id 1
    questionnaire_id 1
    question_id 1
    title 'bla bla'
    body 'cc ccc'
    order 1
    network_id 1
    min 0
    max 20
    active true
  end
end