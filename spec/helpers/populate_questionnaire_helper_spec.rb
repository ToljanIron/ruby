require 'spec_helper'
require './spec/spec_factory'
include FactoryBot::Syntax::Methods

describe PopulateQuestionnaireHelper, type: :helper do
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  before do
    DatabaseCleaner.clean_with(:truncation)
  end

  def create_friendship_questions(emp, questions)
    nn = NetworkName.create(company_id: emp[:company_id], name: 'Friendship')
    questions.each { |fqn| fqn.update(network_id: nn.id) }
    questions
  end

  def make_friends(emp, friendship_questions, emp_ids) # ideally emp and emp_ids should be participant ids
    emp_ids.each do |friend_id|
      friendship_questions.each do |fqn|
        QuestionReply.create(
          questionnaire_id: fqn[:questionnaire_id],
          questionnaire_question_id: fqn.id,
          questionnaire_participant_id: emp.id,
          reffered_questionnaire_participant_id: friend_id,
          answer: QuestionnaireParticipant.find(friend_id)[:employee_id].even? # making friends only with even id'ed employees
        )
      end
    end
  end

  describe 'run' do
    it 'should call functions' do
      create(:employee)
      expect(PopulateQuestionnaireHelper).to receive(:answered_before?).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:who_picked_me).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:under_same_manager).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:under_me).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:my_peer_receivers).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:in_my_group).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:in_sibling_groups).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:in_parent_group).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:in_daughter_groups).and_return({})
      expect(PopulateQuestionnaireHelper).to receive(:random_emps).and_return({})
      PopulateQuestionnaireHelper.run(1)
    end

    it 'should call write for all emps with key: emp_id and value: array of ids' do
      create_list(:employee, 3)

      allow(PopulateQuestionnaireHelper).to receive(:my_peer_receivers).and_return({})
      allow(PopulateQuestionnaireHelper).to receive(:in_my_group).and_return({})
      allow(PopulateQuestionnaireHelper).to receive(:in_sibling_groups).and_return({})
      allow(PopulateQuestionnaireHelper).to receive(:in_parent_group).and_return({})
      allow(PopulateQuestionnaireHelper).to receive(:in_daughter_groups).and_return({})

      expected_connections = {}
      expected_connections[Employee.first.id.to_s] = [2, 3]
      expected_connections[Employee.second.id.to_s] = [3, 1]
      expected_connections[Employee.last.id.to_s] = [2, 1]
      RSpec::Matchers.define :hash_with_arrays_like do |expected|
        match do |actual|
          actual.all? do |k, v|
            expected.keys.include?(k) &&
              expected[k].each { |arr_v| v.include? arr_v }
          end
        end
      end
      expect(PopulateQuestionnaireHelper).to receive(:write).with(hash_with_arrays_like(expected_connections))
      PopulateQuestionnaireHelper.run(1)
    end
  end

  describe 'write' do
    let(:emp) { create(:employee, id: 0) }

    it 'should write to db for each emp' do
      connections = {}
      connections[emp.id.to_s] = [1, 2, 3]
      PopulateQuestionnaireHelper.write(connections)
      expect(EmployeesConnection.count).to eq(3)
      expect(EmployeesConnection.pluck(:employee_id)).to eq([0, 0, 0])
      expect(EmployeesConnection.pluck(:connection_id)).to eq([1, 2, 3])
    end

    it 'should raise ActiveRecord::Rollback if got an exception' do
      expect(PopulateQuestionnaireHelper).to receive(:raise).with(ActiveRecord::Rollback)
      PopulateQuestionnaireHelper.write('0': [1, 2, nil])
    end

    it 'should delete previous connections if not in new connections' do
      EmployeesConnection.create(employee_id: emp.id, connection_id: 4)
      PopulateQuestionnaireHelper.write('0': [1, 2, 3])
      expect(EmployeesConnection.all.to_a.map(&:attributes)).to_not include(employee_id: 1, connection_id: 4)
    end
  end

  describe 'random_emps' do
    let(:emp) { create(:employee, id: 0) }

    it 'should return hash of size company_maximum - connections.size' do
      create_list(:employee, 50)
      connections = (1..10).map { |e| [e, nil] }.to_h
      expect(PopulateQuestionnaireHelper.random_emps(emp, connections, 15).size).to eq(5)
    end

    it 'should not contain emp id or any of the connections ids' do
      create_list(:employee, 4)
      connections = (1..2).map { |e| [e, nil] }.to_h
      res = PopulateQuestionnaireHelper.random_emps(emp, connections, 4).keys
      expect(res).to_not include(emp.id)
      expect(res).to_not include(1)
      expect(res).to_not include(2)
    end
  end

  describe 'in_daughter_groups' do
    let(:emp) { create(:employee, id: 0, group_id: 1) }

    it 'should return emps in all daughter groups' do
      create_list(:group, 4)
      Group.last(2).each { |g| g.update(parent_group_id: emp[:group_id]) }
      emps = create_list(:employee, 7)
      emps.each do |e|
        gid = 1 if e.id == 1
        gid = 2 if [2, 3].include?(e.id)
        gid = 3 if [4, 5].include?(e.id)
        gid = 4 if [6, 7].include?(e.id)
        e.update(group_id: gid)
      end
      expect(PopulateQuestionnaireHelper.in_daughter_groups(emp).length).to eq(4)
      expect(PopulateQuestionnaireHelper.in_daughter_groups(emp).keys).to include(4)
      expect(PopulateQuestionnaireHelper.in_daughter_groups(emp).keys).to include(5)
      expect(PopulateQuestionnaireHelper.in_daughter_groups(emp).keys).to include(6)
      expect(PopulateQuestionnaireHelper.in_daughter_groups(emp).keys).to include(7)
    end
  end

  describe 'in_parent_group' do
    let(:emp) { create(:employee, id: 0, group_id: 1) }

    it 'should return emps in parent group' do
      create_list(:group, 2)
      Group.find(emp[:group_id]).update(parent_group_id: 2)
      create_list(:employee, 3)
      Employee.first.update(group_id: 1)
      Employee.last(2).each { |e| e.update(group_id: 2) }
      expect(PopulateQuestionnaireHelper.in_parent_group(emp).length).to eq(2)
      expect(PopulateQuestionnaireHelper.in_parent_group(emp).keys).to include(2)
      expect(PopulateQuestionnaireHelper.in_parent_group(emp).keys).to include(3)
    end
  end

  describe 'in_sibling_groups' do
    let(:emp) { create(:employee, id: 0, group_id: 1) }

    it 'should return employees in sibling groups' do
      create_list(:group, 4)
      Group.first(3).each { |g| g.update(parent_group_id: 100) }
      emps = create_list(:employee, 7)
      emps.each do |e|
        gid = emp[:group_id] if e.id == 1
        gid = 2 if [2, 3].include?(e.id)
        gid = 3 if [4, 5].include?(e.id)
        gid = 4 if [6, 7].include?(e.id)
        e.update(group_id: gid)
      end
      expect(PopulateQuestionnaireHelper.in_sibling_groups(emp).length).to eq(4)
      expect(PopulateQuestionnaireHelper.in_sibling_groups(emp).keys).to include(2)
      expect(PopulateQuestionnaireHelper.in_sibling_groups(emp).keys).to include(3)
      expect(PopulateQuestionnaireHelper.in_sibling_groups(emp).keys).to include(4)
      expect(PopulateQuestionnaireHelper.in_sibling_groups(emp).keys).to include(5)
    end
  end

  describe 'in_my_group' do
    let(:emp) { create(:employee, id: 0, group_id: 1) }

    it 'should return emps in my group' do
      create_list(:employee, 4)
      Employee.where(id: [1, 2]).each { |e| e.update(group_id: emp[:group_id]) }
      Employee.where(id: [3, 4]).each { |e| e.update(group_id: 100) }
      expect(PopulateQuestionnaireHelper.in_my_group(emp).length).to eq(2)
      expect(PopulateQuestionnaireHelper.in_my_group(emp).keys).to include(1)
      expect(PopulateQuestionnaireHelper.in_my_group(emp).keys).to include(2)
    end
  end

  describe 'my_peer_receivers' do
    let(:emp) { create(:employee, id: 0) }

    before do
      Company.create(name: '1')
    end

  #   it 'should return emps only in meaningful relation with emp' do   #ASAF BYEBUG DEAD CODE REDUNDANT?
  #     sn = create(:snapshot)
  #     (1..3).each do |id|
  #       create(:email_snapshot_data, employee_from_id: emp.id, employee_to_id: id, significant_level: 4 - id, snapshot_id: sn.id)
  #     end
  #     res = PopulateQuestionnaireHelper.my_peer_receivers(emp)
  #     expect(res[1]).to eq(PopulateQuestionnaireHelper::PEER_RECEIVER * 3)
  #   end

  #   it 'should count only meaningful relations in last snapshot' do   #ASAF BYEBUG DEAD CODE REDUNDANT?
  #     (0..1).each do |s|
  #       sn = create(:snapshot, company_id: emp[:company_id], timestamp: Time.now + s)
  #       create(:email_snapshot_data, employee_from_id: emp.id, employee_to_id: s + 1, significant_level: 3, snapshot_id: sn.id)
  #     end
  #     expect(PopulateQuestionnaireHelper.my_peer_receivers(emp).keys).to eq([2])
  #   end
  end

  describe 'under me' do
    let(:emp) { create(:employee, id: 0) }

    it 'should return {} if emp is not a manager' do
      expect(PopulateQuestionnaireHelper.under_me(emp)).to eq({})
    end

    it 'should return all emps under emp if he is a manager' do
      (1..10).each { |id| create(:employee_management_relation, employee_id: id, manager_id: emp.id) }
      expected_array = (1..10).to_a
      expect(PopulateQuestionnaireHelper.under_me(emp)).to eq(expected_array.map { |e| [e, PopulateQuestionnaireHelper::UNDER_ME] }.to_h)
    end

    it 'should not return other emps' do
      (1..10).each { |id| create(:employee_management_relation, employee_id: id, manager_id: emp.id) }
      (11..20).each { |id| create(:employee_management_relation, employee_id: id, manager_id: 100) }
      expected_array = (1..10).to_a
      expect(PopulateQuestionnaireHelper.under_me(emp)).to eq(expected_array.map { |e| [e, PopulateQuestionnaireHelper::UNDER_ME] }.to_h)
    end
  end

  describe 'under_same_manager' do
    let(:emp) { create(:employee, id: 0) }

    it 'should return {} if emp has no direct manager' do
      expect(PopulateQuestionnaireHelper.under_same_manager(emp)).to eq({})
    end

    it 'should return all emps under the same manager if there\s one' do
      (2..10).each do |id|
        create(:employee_management_relation, employee_id: id) # manager_id = 1
      end
      create(:employee_management_relation, employee_id: emp.id)
      expected_array = (2..10).to_a
      expect(PopulateQuestionnaireHelper.under_same_manager(emp)).to eq(expected_array.map { |e| [e, PopulateQuestionnaireHelper::UNDER_SAME_MANAGER] }.to_h)
    end

    it 'should return all emps under same managers without overlaps if theres more than one' do
      (3..10).each { |id| create(:employee_management_relation, employee_id: id) }
      (5..15).each { |id| create(:employee_management_relation, employee_id: id, manager_id: 2) }
      create(:employee_management_relation, employee_id: emp.id)
      create(:employee_management_relation, employee_id: emp.id, manager_id: 2)
      expected_array = (3..15).to_a
      expect(PopulateQuestionnaireHelper.under_same_manager(emp)).to eq(expected_array.map { |e| [e, PopulateQuestionnaireHelper::UNDER_SAME_MANAGER] }.to_h)
    end

    it 'should not include emps not under the same manager' do
      (2..10).each { |id| create(:employee_management_relation, employee_id: id) }
      (11..15).each { |id| create(:employee_management_relation, employee_id: id, manager_id: 100) }
      create(:employee_management_relation, employee_id: emp.id)
      expected_array = (2..10).to_a
      expect(PopulateQuestionnaireHelper.under_same_manager(emp)).to eq(expected_array.map { |e| [e, PopulateQuestionnaireHelper::UNDER_SAME_MANAGER] }.to_h)
    end
  end

  describe 'who_picked_me' do
    let(:emp) { create(:employee) }

    before do
      create_list(:employee, 5)
      create_list(:question, 4)
      InteractBackofficeActionsHelper.create_new_questionnaire(emp[:company_id])
      @q1 = Questionnaire.last
    end

    it 'should return {} if last questionnaire was completed' do
      @q1.update(state: 'completed')
      expect(PopulateQuestionnaireHelper.who_picked_me(emp)).to eq({})
    end
  end

  describe 'answered_before?' do
    let(:emp) { create(:employee) }

    before do
      @comp = Company.create(name: 'comp')
    end

    it 'should return false if no questionnaires ever ran in a company' do
      Questionnaire.where(company_id: emp[:company_id]).delete_all
      QuestionnaireParticipant.where(employee_id: Employee.where(company_id: emp[:company_id]).pluck(:id)).delete_all
      expect(PopulateQuestionnaireHelper.answered_before?(emp)).to be_falsey
    end

    it 'should return false if theres just one questionnaire which he didnt answer yet' do
      InteractBackofficeActionsHelper.create_new_questionnaire(emp[:company_id])
      expect(PopulateQuestionnaireHelper.answered_before?(emp)).to be_falsey
    end

    it 'should return true if he completed any questionnaire in the past' do
      InteractBackofficeActionsHelper.create_new_questionnaire(emp[:company_id])
      QuestionnaireParticipant.create!(employee_id: emp.id, questionnaire_id: 12, status: :completed)
      expect(PopulateQuestionnaireHelper.answered_before?(emp)).to be_truthy
    end
  end

  describe 'sum hashes' do
    it 'should sum values of two hashes with same keys by key' do
      a = { q: 1, w: 2, e: 3 }
      b = { q: 1, w: 3, e: 5 }
      expect(PopulateQuestionnaireHelper.sum_hashes(a, b)).to eq(q: 2, w: 5, e: 8)
    end

    it 'should return first hash when second is empty' do
      a = { q: 1, w: 2, e: 3 }
      expect(PopulateQuestionnaireHelper.sum_hashes(a, {})).to eq(a)
    end

    it 'should return second hash when first is empty' do
      b = { q: 1, w: 2, e: 3 }
      expect(PopulateQuestionnaireHelper.sum_hashes({}, b)).to eq(b)
    end

    it 'should merge two hashes when no repeating keys' do
      a = { q: 1, w: 2 }
      b = { e: 3, r: 4, t: 5 }
      expect(PopulateQuestionnaireHelper.sum_hashes(a, b)).to eq(q: 1, w: 2, e: 3, r: 4, t: 5)
    end

    it 'should sum values under same key and add those without a pair' do
      a = { q: 1, w: 2, e: 3 }
      b = { w: 4, e: 5, r: 6 }
      expect(PopulateQuestionnaireHelper.sum_hashes(a, b)).to eq(q: 1, w: 6, e: 8, r: 6)
    end
  end
end
