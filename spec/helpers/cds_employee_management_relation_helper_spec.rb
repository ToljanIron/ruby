require 'spec_helper'
require './spec/spec_factory'

describe CdsEmployeeManagementRelationHelper, type: :helper do
  describe 'testing ' do
    before do
      c1 = Company.create(name: 'c1')
      c2 = Company.create(name: 'c2')

      @em0 = 'p0@email.com'
      @em1 = 'p1@email.com'
      @em2 = 'p2@email.com'
      @em3 = 'p3@email.com'
      @em4 = 'p4@email.com'
      @em5 = 'p5@email.com'
      @em6 = 'p6@email.com'
      @em7 = 'p7@email.com'
      @em8 = 'p8@email.com'
      @em9 = 'p9@email.com'
      @em10 = 'p10@email.com'
      @em11 = 'p11@email.com'
      @sshot1 = Snapshot.create(name: 's1', company_id: c1.id)

      @g1 = FactoryGirl.create(:group, name: 'group_1', company_id: c1.id)
      @g2 = FactoryGirl.create(:group, name: 'group_2', company_id: c1.id, parent_group_id: 1)
      @g3 = FactoryGirl.create(:group, name: 'group_3', company_id: c1.id)

      e0 = FactoryGirl.create(:employee, email:  @em0, group_id: 2)
      e1 = FactoryGirl.create(:employee, email:  @em1, group_id: 2)
      e2 = FactoryGirl.create(:employee, email:  @em2, group_id: 3)
      e3 = FactoryGirl.create(:employee, email:  @em3, group_id: 3)
      e4 = FactoryGirl.create(:employee, email:  @em4, group_id: 3)
      e5 = FactoryGirl.create(:employee, email:  @em5, group_id: 3)
      e6 = FactoryGirl.create(:employee, email:  @em6, group_id: 3)
      e7 = FactoryGirl.create(:employee, email:  @em7, group_id: 3)
      e8 = FactoryGirl.create(:employee, email:  @em8, group_id: 3)
      e9 = FactoryGirl.create(:employee, email:  @em9, group_id: 3)

      FactoryGirl.create(:employee_management_relation, manager_id: 3, employee_id: 4)
      FactoryGirl.create(:employee_management_relation, manager_id: 3, employee_id: 5)
      FactoryGirl.create(:employee_management_relation, manager_id: 3, employee_id: 6)
      FactoryGirl.create(:employee_management_relation, manager_id: 7, employee_id: 8)
      FactoryGirl.create(:employee_management_relation, manager_id: 7, employee_id: 9)
      FactoryGirl.create(:employee_management_relation, manager_id: 10, employee_id: 3)
      FactoryGirl.create(:employee_management_relation, manager_id: 11, employee_id: 7)
      FactoryGirl.create(:employee_management_relation, manager_id: 12, employee_id: 9)

      @n1 = FactoryGirl.create(:network_name, name: 'FriendShip', company_id: 0)

      NetworkSnapshotData.create(company_id: c1.id, from_employee_id: 3, to_employee_id: 2, value: 1, snapshot_id: @sshot1.id, network_id: @n1.id)
      NetworkSnapshotData.create(company_id: c1.id, from_employee_id: 4, to_employee_id: 1, value: 1, snapshot_id: @sshot1.id, network_id: @n1.id)
      NetworkSnapshotData.create(company_id: c1.id, from_employee_id: 4, to_employee_id: 1, value: 1, snapshot_id: @sshot1.id, network_id: @n1.id)
      NetworkSnapshotData.create(company_id: c1.id, from_employee_id: 2, to_employee_id: 5, value: 1, snapshot_id: @sshot1.id, network_id: @n1.id)

      @pin = Pin.create(company_id: 1, name: 'testpin', definition: 'some def')
      EmployeesPin.create(pin_id: @pin.id, employee_id: e0.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e1.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e2.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: e3.id)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    describe 'calculating r_in ' do
      it ' for company , return 3 for manager id3 and 2 for manager id7' do
        res = get_r_in(1, -1, -1)
        expected_result = [{ id: 3, measure: 3.to_s }, { id: 7, measure: 2.to_s }]
        expect(res).to eq(expected_result)
      end

      it ' for group 3 , return 3 for manager id3 and 2 for manager id7' do # TODO: rewrite according to changes in bypassed manager
        res = get_r_in(1, -1, @g3.id)
        expected_result = [{ id: 3, measure: 3.to_s }, { id: 7, measure: 2.to_s }]
        expect(res).to eq(expected_result)
      end
    end
    describe ' test create relation matrix for company' do
      it 'its size should equal 10 * 9 = 90 ' do
        res = create_relation_matrix(1, -1, -1)
        expect(res.length).to eq(90)
      end

      it 'its size should equal 8 * 7 = 56 for group 3' do
        res = create_relation_matrix(1, -1, 3)
        expect(res.length).to eq(56)
      end

      it 'its size should equal 4 * 3 = 12 for pin1' do
        res = create_relation_matrix(1, @pin.id, -1)
        expect(res.length).to eq(12)
      end
      it 'test combination of a matrix and r matrix to informal_matrix' do
        advise_relations = [{ from: 1, to: 2, value: 1 }, { from: 1, to: 3, value: 0 }, { from: 1, to: 4, value: 0 }, { from: 2, to: 3, value: 1 }]
        employee_relations = [{ from: 1, to: 2, value: 0 }, { from: 1, to: 3, value: 1 }, { from: 1, to: 4, value: 0 }, { from: 2, to: 3, value: 1 }]
        res = combine_r_and_a_matrices(advise_relations, employee_relations)
        expect(res).to include(from: 1, to: 2, value: 10)
        expect(res).to include(from: 1, to: 3, value: 1)
        expect(res).to include(from: 1, to: 4, value: 0)
        expect(res).to include(from: 2, to: 3, value: 11)
      end
    end
    describe 'test reduce_informal_subordinate_non_advised_by_to' do
      it 'should return reduce of values per distinct to' do
        example_matrix = [{ to: 2, from: 5, value: 1 }, { to: 4, from: 3, value: 1 }, { to: 3, from: 6, value: 1 }, { to: 3, from: 11, value: 1 }, { to: 3, from: 1, value: 1 }]
        res = reduce_informal_subordinate_non_advised_by_to(example_matrix)
        expect(res).to include(id: 2, measure: 1)
        expect(res).to include(id: 3, measure: 3)
        expect(res).to include(id: 4, measure: 1)
      end
    end
    describe 'test get_bypassed_in' do
      before do
        FactoryGirl.create(:employee, email: @em10, group_id: 3)
        FactoryGirl.create(:employee, email: @em11, group_id: 3)
      end
      after do
        DatabaseCleaner.clean_with(:truncation)
      end
      it 'should only output employee ids of managers who have employees that dont seek their advice ' do
        example_matrix = [{ to: 2, from: 5, value: 1 }, { to: 4, from: 3, value: 1 }, { to: 3, from: 6, value: 1 }, { to: 3, from: 11, value: 1 }, { to: 3, from: 1, value: 1 }, { to: 3, from: 12, value: 0 }]
        res = get_bypassed_in(example_matrix, 1)
        expect(res).to include(id: 3, measure: 1.0)
      end
    end
  end
end
