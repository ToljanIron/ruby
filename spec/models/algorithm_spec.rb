require 'spec_helper'

describe Algorithm, type: :model do
  before do
    @algorithm = Algorithm.create(name: 'Example', algorithm_type_id: 2)
  end
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:algorithm_type_id) }

  it 'creating 2 network names with the same company_id should not be ok' do
    @algorithm = Algorithm.create(name: 'Example', algorithm_type_id: 3)
    algorithm_with_same_algorithm_type_id = @algorithm.dup
    expect(algorithm_with_same_algorithm_type_id.save).to eq false
  end

  it 'creating 2 network names with the same company_id shouldbe ok' do
    @algorithm = Algorithm.create(name: 'Example', algorithm_type_id: 3)
    algorithm_with_same_algorithm_type_id = @algorithm.dup
    algorithm_with_same_algorithm_type_id.algorithm_type_id = 4
    expect(algorithm_with_same_algorithm_type_id.save).to eq true
  end
end
