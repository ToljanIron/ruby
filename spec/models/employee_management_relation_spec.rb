require 'spec_helper'

describe EmployeeManagementRelation, type: :model do

  before do
    @relation = EmployeeManagementRelation.new
  end

  subject { @relation }

  it { is_expected.to respond_to(:manager_id) }
  it { is_expected.to respond_to(:employee_id) }
  it { is_expected.to respond_to(:relation_type) }

  describe 'with invalid data should be invalid' do
    it { is_expected.not_to be_valid }
  end

  describe ', with valid data should be valid' do
    it do
      subject[:manager_id] = 1
      subject[:employee_id] = 2
      subject[:relation_type] = 'direct'
      is_expected.to be_valid
    end
  end

end
