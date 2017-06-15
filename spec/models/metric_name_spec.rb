require 'spec_helper'

describe MetricName, type: :model do
  before do
    @metric_name = MetricName.create(name: 'Example', company_id: 2)
  end
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:company_id) }

  it 'creating 2 network names with the same company_id shouldbe ok' do
    @metric_name = MetricName.create(name: 'Example', company_id: 3)
    metric_with_same_email = @metric_name.dup
    metric_with_same_email.company_id = 4
    expect(metric_with_same_email.save).to eq true
  end
end
