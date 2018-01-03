FactoryGirl.define do
  factory :company_metric do
    company_id 1
    algorithm_type 1
    network_id 1

    before(:create) do |order, evaluator|
      #FactoryGirl.create_list :order_line, evaluator.number_or_order_lines, order: order
    end
  end
end
