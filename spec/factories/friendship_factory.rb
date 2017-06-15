FactoryGirl.define do
  factory :friendship do
    employee_id 1
    friend_id 2
    friend_flag Random.rand(2)
  end
end
