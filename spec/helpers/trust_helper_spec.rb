require 'spec_helper.rb'
require './spec/spec_factory.rb'
require './spec/factories/company_with_metrics_factory.rb'
#include CompanyWithMetricsFactory

describe TrustHelper, type: :helper do
  let(:emp1) { FactoryGirl.create(:employee, email: 'e1@e.com', company_id: 1) }
  let(:emp2) { FactoryGirl.create(:employee, email: 'e2@e.com', company_id: 1) }

  before(:each) do
    FactoryGirl.create(:metric, name: 'analyze trust', metric_type: 'analyze', index: 4)
    Company.create(id: 1, name: 'company1')
    @n1 = FactoryGirl.create(:network_name, name: 'Trust', company_id: 1)
    current_time = Time.now
    @time_to_client = current_time.to_i * 1000
    snapshot_factory_create({id: 1, company_id: 1, timestamp: current_time})
    NetworkSnapshotData.create!(from_employee_id: emp1[:id], to_employee_id: emp2[:id], value: 1, snapshot_id: 1, company_id: 1, network_id: @n1.id)
  end

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'calculate_pair_trusted_per_snapshot' do
    it 'should return empty array if trust matrix is empty' do
      NetworkSnapshotData.destroy_all
      result = AlgorithmsHelper.calculate_pair_for_specific_relation_per_snapshot(1, @n1.id, -1, -1)
      expect(result).to be_empty
    end

    describe 'if trust matrix contains one record' do
      it 'should return empty array if trust_flag is 0' do
        NetworkSnapshotData.find(1).update(value: 0)
        result = AlgorithmsHelper.calculate_pair_for_specific_relation_per_snapshot(1, @n1.id, -1, -1)
        expect(result).to be_empty
      end
    end

    describe 'get_trust_in_network' do
      it 'should return score for employee who\'s trusted' do
        result = get_trust_in_network(1, @n1.id, -1, -1)
        expect(result[0][:id]).to eq 2
      end

      it 'should not return score for employee to whom trusts nobody' do
        result = get_trust_in_network(1, @n1.id)
        expect(result.map { |r| r[:id] }).not_to include 1
      end

      it 'should return empty array if no trust data' do
        NetworkSnapshotData.destroy_all
        result = get_trust_in_network(1, @n1.id, -1, -1)
        expect(result).to be_empty
      end

      it 'should return measure 0 if trust_flag is 0' do
        NetworkSnapshotData.find(1).update(value: 0)
        result = get_trust_in_network(1, @n1.id)
        expect(result).to include(id: 2, measure: "0.0")
      end
    end
  end
end
