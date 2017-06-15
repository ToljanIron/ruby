require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryGirl::Syntax::Methods

#include CompanyWithMetricsFactory

IN = 'employee_to_id'
OUT  = 'employee_from_id'
TO_MATRIX ||= 1
CC_MATRIX ||= 2
BCC_MATRIX ||= 3

describe AlgorithmsHelper, type: :helper do
  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
  end

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'Email related tests' do
    before(:each) do
      @c1 = Company.create(name: 'company1')
      @c2 = Company.create(name: 'company2')
      @sshot1 = FactoryGirl.create(:snapshot, name: 's1', snapshot_type: nil, company_id: @c1.id)
      @sshot2 = FactoryGirl.create(:snapshot, name: 's2', snapshot_type: nil, company_id: @c2.id)
      @g1 = FactoryGirl.create(:group, company_id: @c1.id)
      @g2 = FactoryGirl.create(:group, company_id: @c1.id, parent_group_id: @g1.id)
      @e1 = Employee.create!(email: create_unique_email, company_id: @c1.id, first_name: 'a', last_name: 'e', external_id: create_unique_external_id,
                             group_id: @g1.id)
      @e2 = Employee.create!(email: create_unique_email, company_id: @c1.id, first_name: 'a', last_name: 'e', external_id: create_unique_external_id,
                             group_id: @g2.id)
      @e3 = Employee.create!(email: create_unique_email, company_id: @c1.id, first_name: 'a', last_name: 'e', external_id: create_unique_external_id,
                             group_id: @g2.id)
      @e4 = Employee.create!(email: create_unique_email, company_id: @c1.id, first_name: 'a', last_name: 'e', external_id: create_unique_external_id,
                             group_id: @g1.id)

      @e5 = Employee.create!(email: create_unique_email, company_id: @c2.id, first_name: 'a', last_name: 'e', external_id: create_unique_external_id)
      @e6 = Employee.create!(email: create_unique_email, company_id: @c2.id, first_name: 'a', last_name: 'e', external_id: create_unique_external_id)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: @c1.id)
      NetworkName.find_or_create_by!(id: 124, name: "Communication Flow", company_id: @c2.id)      
      @nsn1 = NetworkSnapshotData.create_email_adapter(employee_to_id: @e1.id, employee_from_id: @e2.id,
                                         snapshot_id: @sshot1.id, n1: 1, n4: 2, n7: 3, n10: 4, n13: 5, n16: 6,
                                         n2: 2, n5: 6, n8: 1, n11: 0, n14: 3, n17: 1,
                                         n3: 1, n6: 2, n9: 2, n12: 1, n15: 2, n18: 1)
      @nsn2 = NetworkSnapshotData.create_email_adapter(employee_to_id: @e1.id, employee_from_id: @e3.id,
                                         snapshot_id: @sshot1.id, n1: 1, n4: 2, n7: 1, n10: 1, n13: 1, n16: 2,
                                         n2: 1, n5: 1, n8: 1, n11: 0, n14: 2, n17: 1,
                                         n3: 1, n6: 1, n9: 1, n12: 0, n15: 1, n18: 2)
      @nsn3 = NetworkSnapshotData.create_email_adapter(employee_to_id: @e2.id, employee_from_id: @e1.id,
                                         snapshot_id: @sshot1.id, n1: 1, n4: 2, n7: 2, n10: 1, n13: 1, n16: 2,
                                         n2: 1, n5: 3, n8: 2, n11: 1, n14: 2, n17: 0,
                                         n3: 1, n6: 1, n9: 0, n12: 1, n15: 1, n18: 1)
      @nsn4 = NetworkSnapshotData.create_email_adapter(employee_to_id: @e3.id, employee_from_id: @e2.id,
                                         snapshot_id: @sshot1.id, n1: 1, n4: 2, n7: 3, n10: 1, n13: 1, n16: 2,
                                         n2: 3, n5: 6, n8: 2, n11: 5, n14: 1, n17: 2,
                                         n3: 2, n6: 3, n9: 3, n12: 4, n15: 1, n18: 1)

      @nsn21 = NetworkSnapshotData.create_email_adapter(employee_to_id: @e5.id, employee_from_id: @e6.id,
                                         snapshot_id: @sshot2.id, n1: 0, n4: 0, n7: 0, n10: 0, n13: 0, n16: 0,
                                         n2: 0, n5: 0, n8: 0, n11: 0, n14: 0, n17: 0,
                                         n3: 0, n6: 0, n9: 0, n12: 0, n15: 0, n18: 0)
      @nsn21 = NetworkSnapshotData.create_email_adapter(employee_to_id: @e6.id, employee_from_id: @e5.id,
                                         snapshot_id: @sshot2.id, n1: 0, n4: 0, n7: 0, n10: 0, n13: 0, n16: 0,
                                         n2: 0, n5: 0, n8: 0, n11: 0, n14: 0, n17: 0,
                                         n3: 0, n6: 0, n9: 0, n12: 0, n15: 0, n18: 0)
      @pin1 = Pin.create(company_id: @c1.id)

      [@e1, @e2].each do |emp|
        EmployeesPin.create(pin_id: @pin1.id, employee_id: emp.id)
      end
    end

    describe 'indegrees' do
      describe 'indegree of TO for company' do
        it 'should equal ' do
          res = calc_indegree_for_to_matrix(@sshot1, -1, -1)
          expect(res.size).to eql(3)
          res.each do |emp|
            expect(emp[:measure]).to eql(29) if emp[:id] == @e1[:id]
            expect(emp[:measure]).to eql(9)  if emp[:id] == @e2[:id]
            expect(emp[:measure]).to eql(10) if emp[:id] == @e3[:id]
          end
        end
      end
      describe 'indegree of CC for pin1' do
        it 'should equal ' do
          res = calc_indegree_for_cc_matrix(@sshot1, -1, @pin1.id)
          expect(res.size).to eql(2)
          res.each do |emp|
            expect(emp[:measure]).to eql(13) if emp[:id] == @e1[:id]
            expect(emp[:measure]).to eql(9)  if emp[:id] == @e2[:id]
          end
        end
      end


    end
    describe 'outdegrees' do
      describe 'outdegree of TO' do
        it 'should equal ' do
          res = calc_outdegree_for_to_matrix(@sshot1, -1, -1)
          expect(res.size).to eql(3)
          res.each do |emp|
            expect(emp[:measure]).to eql(9) if emp[:id] == @e1[:id]
            expect(emp[:measure]).to eql(31)  if emp[:id] == @e2[:id]
            expect(emp[:measure]).to eql(8) if emp[:id] == @e3[:id]
          end
        end
      end
      describe 'outdegree of BCC for group2' do
        it 'should equal ' do
          res = calc_outdegree_for_bcc_matrix(@sshot1, @g2.id, -1)
          expect(res.size).to eql(1)
          res.each do |emp|
            expect(emp[:measure]).to eql(14) if emp[:id] == @e2[:id]
          end
        end
      end
      describe 'outdegree of ALL for group2' do
        it 'should equal ' do
          res = calc_outdegree_for_all_matrix(@sshot1, @g2.id, -1)
          expect(res.size).to eql(1)
          expect(res).to include({ id: @e2[:id], measure: 43.round(2) })
        end
      end
    end

    describe 'calculating maxima' do
      it 'should calculate the maximum in indeg_to for the entire company' do
        res = calc_max_indegree_for_specified_matrix(@sshot1.id, TO_MATRIX)
        expect(res).to eql(29)
      end
      it 'should calculate the maximum in outdeg_to for the entire company' do
        res = calc_max_outdegree_for_specified_matrix(@sshot1.id, TO_MATRIX)
        expect(res).to eql(31)
      end
    end

    describe 'calculating averages' do
      it 'should calculate the average  indeg_to for the entire company' do
        res = calc_avgin_degree_for_to_matrix(@sshot1.id)
        expect(res).to eql(12.0)
      end
      it 'should calculate the average  outdeg_to for the entire company' do
        res = calc_avgout_degree_for_to_matrix(@sshot1.id)
        expect(res).to eql(12.0)
      end
      it 'should calculate the average indeg_cc for the entire company' do
        res = calc_avgin_degree_for_cc_matrix(@sshot1.id)
        expect(res).to eql((47 / 4.to_f).to_f.round(2))
      end
      it 'should calculate the average outdeg_cc for the entire company' do
        res = calc_avgout_degree_for_cc_matrix(@sshot1.id)
        expect(res).to eql((47 / 4.to_f).to_f.round(2))
      end

      it 'should calculate the average indeg_cc for the entire company' do
        res = calc_avgin_degree_for_bcc_matrix(@sshot1.id)
        expect(res).to eql((34 / 4.to_f).to_f.round(2))
      end
      it 'should calculate the average outdeg_bcc for the entire company' do
        res = calc_avgout_degree_for_bcc_matrix(@sshot1.id)
        expect(res).to eql((34.to_f / 4).to_f.round(2))
      end

      it 'should calculate 0 average for company 2 that has no email traffic' do
        res = calc_avgout_degree_for_all_matrix(@sshot2.id)
        expect(res).to eql((0).to_f.round(2))
      end
    end

    describe 'calculating normalized results' do
      it 'should calculate the normalized  indeg_to for the entire company' do
        res = calc_normalized_indegree_for_to_matrix(@sshot1.id, -1, -1)
        expect(res). to include(id: @e1.id, measure: 1)
      end
      it 'should calculate the normalized  outdeg_to for the entire company' do
        res = calc_normalized_outdegree_for_to_matrix(@sshot1.id, -1, -1)
        expect(res). to include(id: @e1.id, measure: (9 / 31.to_f).round(2))
      end

      it 'should return -1\'s when there is no data for company 2' do
        res = calc_normalized_outdegree_for_to_matrix(@sshot2.id, -1, -1)
        expect(res). to eq(-1)
      end
      it 'should return -1\'s when there is no data for company 2' do
        res = calc_normalized_outdegree_for_all_matrix(@sshot2.id, -1, -1)
        expect(res). to eq(-1)
    end
  end

    describe 'centrality metric' do
      it 'should calculate normalized indegree for the all matrix' do
        res = centrality(@sshot1.id, -1, -1)
        expect(res).to include(id: @e1.id, measure: 1)
        expect(res).to include(id: @e2.id, measure: (23.to_f / 63).round(2))
        expect(res).to include(id: @e3.id, measure: (43.to_f / 63).round(2))
      end
    end

    describe 'central metric' do
      it 'should calculate normalized indegree for the to matrix' do
        res = central(@sshot1.id, -1, -1)
        expect(res).to include(id: @e1.id, measure: 1)
        expect(res).to include(id: @e2.id, measure: (9.to_f / 29).round(2))
        expect(res).to include(id: @e3.id, measure: (10.to_f / 29).round(2))
      end
    end

    describe 'In the Loop metric' do
      it 'should calculate normalized indegree for the to matrix on group2' do
        res = in_the_loop(@sshot1.id, @g2.id, -1)
        expect(res.size).to eql(1)
        expect(res).to include(id: @e3.id, measure: 1)
      end
      it 'should calculate normalized indegree for the cc matrix on company1' do
        res = in_the_loop(@sshot1.id, -1, -1)
        expect(res.size).to eql(3)
        expect(res).to include(id: @e1.id, measure: 1)
        expect(res).to include(id: @e2.id, measure: (9.to_f / 19).round(2))
        expect(res).to include(id: @e3.id, measure: (19.to_f / 19).round(2))
      end
    end

    describe 'political centrality metric' do
      it 'should calculate normalized indegree for the bcc matrix' do
        res = politician(@sshot1.id, -1, -1)
        expect(res).to include(id: @e1.id, measure: 1)
        expect(res).to include(id: @e2.id, measure: (5.to_f / 15).round(2))
        expect(res).to include(id: @e3.id, measure: (14.to_f / 15).round(2))
      end
    end

    describe 'total activity metric' do
      it 'should calculate normalized indegree for the to matrix' do
        res = total_activity_centrality(@sshot1.id, -1, -1)
        expect(res).to include(id: @e1.id, measure: (23.to_f / 86).round(2))
        expect(res).to include(id: @e2.id, measure: 1)
        expect(res).to include(id: @e3.id, measure: (20.to_f / 86).round(2))
      end
    end

    describe 'delegator' do
      it 'should calculate normalized outdegree for the to matrix' do
        res = delegator(@sshot1.id, -1, -1)
        expect(res).to include(id: @e2.id, measure: 1)
        expect(res).to include(id: @e1.id, measure: (9.to_f / 31).round(2))
        expect(res).to include(id: @e3.id, measure: (8.to_f / 31).round(2))
      end

      it 'should calculate normalized outdegree for the to matrix for group2' do
        res = delegator(@sshot1.id, @g2.id, -1)
        expect(res.size).to eql(1)
        expect(res).to include(id: @e2.id, measure: (10.to_f / 31).round(2))
      end
    end

    describe 'knowledge distributor' do
      it 'should calculate normalized outdegree for the cc matrix' do
        res = knowledge_distributor(@sshot1.id, -1, -1)
        expect(res).to include(id: @e2.id, measure: 1)
        expect(res).to include(id: @e1.id, measure: (9.to_f / 32).round(2))
        expect(res).to include(id: @e3.id, measure: (6.to_f / 32).round(2))
      end
    end

    describe 'politically active' do
      it 'should calculate normalized outdegree for the bcc matrix' do
        res = politically_active(@sshot1.id, -1, -1)
        expect(res).to include(id: @e2.id, measure: 1)
        expect(res).to include(id: @e1.id, measure: (5.to_f / 23).round(2))
        expect(res).to include(id: @e3.id, measure: (6.to_f / 23).round(2))
      end
    end

    describe 'calc_group_all_matrix' do
      it 'should return as many object as many groups is in the company, squared' do
        result = calc_group_all_matrix(@sshot1.id, [@g1, @g2])
        expect(result.length).to eq 4
      end

      it 'should return one object with score for each pair of groups' do
        result = calc_group_all_matrix(@sshot1.id, [@g1, @g2])
        expect(result).to include(group_id: @g1.id, peer_group_id: @g2.id, score: 66)
        expect(result).to include(group_id: @g1.id, peer_group_id: @g1.id, score: 129)
        expect(result).to include(group_id: @g2.id, peer_group_id: @g1.id, score: 106)
        expect(result).to include(group_id: @g2.id, peer_group_id: @g2.id, score: 43)
      end
    end

    # describe 'most isolated group' do       ASAF BYEBUG on ignore list
    #   before(:each) do
    #     @g3 = FactoryGirl.create(:group, company_id: @c1.id, parent_group_id: 0)
    #     @g1.update(parent_group_id: 0)
    #     @g2.update(parent_group_id: 0)
    #     new_guy = FactoryGirl.create(:employee, email: 'newguy@company.com', group_id: @g3.id)
    #     NetworkSnapshotData.create_email_adapter(employee_from_id: new_guy.id, employee_to_id: 2, n1: 100, n2: 0)
    #   end

    #   it 'should return score for each group' do
    #     result = most_isolated_group_algorithm(@sshot1.id)
    #     expect(result.length).to eq 3
    #   end

    #   it 'should sum scores for peers' do
    #     result = most_isolated_group_algorithm(@sshot1.id)
    #     expect(result).to include(group_id: 1, measure: 1.41)
    #     expect(result).to include(group_id: 2, measure: 0.0)
    #     expect(result).to include(group_id: 3, measure: 2.0)
    #   end
    # end

    # describe 'most aloof group' do
    #   before(:each) do
    #     @g3 = FactoryGirl.create(:group, company_id: @c1.id, parent_group_id: 0)
    #     @g1.update(parent_group_id: 0)
    #     @g2.update(parent_group_id: 0)
    #     new_guy = FactoryGirl.create(:employee, email: 'newguy@company.com', group_id: @g3.id)
    #     NetworkSnapshotData.create_email_adapter(employee_from_id: new_guy.id, employee_to_id: 2, n1: 100, n2: 0)
    #   end

    #   it 'should return score for each group' do
    #     result = most_aloof_group(@sshot1.id)
    #     expect(result.length).to eq 3
    #   end

    #   it 'should sum scores for groups' do
    #     result = most_aloof_group(@sshot1.id)
    #     expect(result).to include(group_id: 1, measure: 0.86)
    #     expect(result).to include(group_id: 2, measure: 0)
    #     expect(result).to include(group_id: 3, measure: 0.4)
    #   end
    # end

    # describe 'most self sufficient group' do
    #   before(:each) do
    #     @g3 = FactoryGirl.create(:group, company_id: @c1.id, parent_group_id: 0)
    #     @g1.update(parent_group_id: 0)
    #     @g2.update(parent_group_id: 0)
    #     new_guy = FactoryGirl.create(:employee, email: 'newguy@company.com', group_id: @g3.id)
    #     NetworkSnapshotData.create_email_adapter(employee_from_id: new_guy.id, employee_to_id: 2, n1: 100, n2: 0)
    #   end

    #   it 'should return score for each group' do
    #     result = most_self_sufficient_group(@sshot1.id)
    #     expect(result.length).to eq 3
    #   end

    #   it 'should return scores for emails inside groups' do
    #     result = most_self_sufficient_group(@sshot1.id)
    #     expect(result).to include(group_id: 1, measure: 0)
    #     expect(result).to include(group_id: 2, measure: 0.19)
    #     expect(result).to include(group_id: 3, measure: 0)
    #   end
    # end

    describe 'normalize group_all_matrix by' do
      before(:each) do
        @g2.update(parent_group_id: nil)
      end

      describe 'group_id (out)' do
        it 'should return the same amount of rows as the original group_all_matrix' do
          result = normalize_group_all_matrix_by(:group_id, @sshot1.id, [@g1, @g2])
          expect(result.length).to eq 4
        end

        it 'should normalize matrix by row' do
          result = normalize_group_all_matrix_by(:group_id, @sshot1.id, [@g1, @g2])
          expect(result).to include(group_id: @g1.id, peer_group_id: @g2.id, score: 1)
          expect(result).to include(group_id: @g1.id, peer_group_id: @g1.id, score: 0)
          expect(result).to include(group_id: @g2.id, peer_group_id: @g1.id, score: (63.0 / 106).round(2))
          expect(result).to include(group_id: @g2.id, peer_group_id: @g2.id, score: (43.0 / 106).round(2))
        end

        it 'should return scores that sum up to the number of groups' do
          result = normalize_group_all_matrix_by(:group_id, @sshot1.id, [@g1, @g2])
          expect(result.inject(0) { |a, e| a + e[:score] }.round).to eq [@g1, @g2].length
        end
      end

      describe 'peer_group_id (in)' do
        it 'should return the same amount of rows as the original group_all_matrix' do
          result = normalize_group_all_matrix_by(:peer_group_id, @sshot1.id, [@g1, @g2])
          expect(result.length).to eq 4
        end

        it 'should normalize matrix by column' do
          result = normalize_group_all_matrix_by(:peer_group_id, @sshot1.id, [@g1, @g2])
          expect(result).to include(group_id: @g1.id, peer_group_id: @g2.id, score: (23.0 / 66).round(2))
          expect(result).to include(group_id: @g2.id, peer_group_id: @g2.id, score: (43.0 / 66).round(2))
          expect(result).to include(group_id: @g1.id, peer_group_id: @g1.id, score: 0)
          expect(result).to include(group_id: @g2.id, peer_group_id: @g1.id, score: 1)
        end

        it 'should return scores that sum up to the number of groups' do
          result = normalize_group_all_matrix_by(:peer_group_id, @sshot1.id, [@g1, @g2])
          expect(result.inject(0) { |a, e| a + e[:score] }.round).to eq [@g1, @g2].length
        end
      end

      describe 'all' do
        it 'should return the same amount of rows as the original group_all_matrix' do
          result = normalize_group_all_matrix_by('all', @sshot1.id, [@g1, @g2])
          expect(result.length).to eq 4
        end

        it 'should normalize matrix by all' do
          result = normalize_group_all_matrix_by('all', @sshot1.id, [@g1, @g2])
          expect(result).to include(group_id: @g1.id, peer_group_id: @g2.id, score: (23.0 / 129).round(2))
          expect(result).to include(group_id: @g2.id, peer_group_id: @g2.id, score: (43.0 / 129).round(2))
          expect(result).to include(group_id: @g1.id, peer_group_id: @g1.id, score: 0)
          expect(result).to include(group_id: @g2.id, peer_group_id: @g1.id, score: (63.0 / 129).round(2))
        end

        it 'should return scores that sum up to 1' do
          result = normalize_group_all_matrix_by('all', @sshot1.id, [@g1, @g2])
          expect(result.inject(0) { |a, e| a + e[:score] }.round).to eq 1
        end
      end
    end
  end
end

def create_unique_external_id
  Employee.all.last.nil? ? 0 : (Employee.all.last.id + 1)
end

def create_unique_email
  index = create_unique_external_id
  return "someone#{index}@company.com"
end

