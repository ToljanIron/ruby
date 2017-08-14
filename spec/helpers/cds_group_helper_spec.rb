require 'spec_helper'

describe CdsGroupsHelper, type: :helper do
  before do
    @g1 = FactoryGirl.create(:group, name: 'group_1', company_id: 0)
    @g2 = FactoryGirl.create(:group, name: 'group_2', company_id: 0)
    @g3 = FactoryGirl.create(:group, name: 'group_3', company_id: 0, parent_group_id: 2)
    @g4 = FactoryGirl.create(:group, name: 'group_4', company_id: 0, parent_group_id: 2)
    @g5 = FactoryGirl.create(:group, name: 'group_5', company_id: 0, parent_group_id: 4)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe ', covert_formal_structure_to_group_id_child_groups_pairs' do
    it 'should return {group_id:id, nil} format' do
      res = CdsGroupsHelper.covert_formal_structure_to_group_id_child_groups_pairs @g1.id
      expect(res).to eq(group_id: 1, child_groups: [])
    end

    it 'should return {group_id:id, child_groups:[...]} in recursive format' do
      res = CdsGroupsHelper.covert_formal_structure_to_group_id_child_groups_pairs @g4.id
      expect(res).to eq(group_id: 4, child_groups: [{ group_id: 5, child_groups: [] }])
    end

    it 'should return {group_id:id, child_groups:[...]} in recursive format' do
      res = CdsGroupsHelper.covert_formal_structure_to_group_id_child_groups_pairs @g2.id
      expect(res).to eq(group_id: 2, child_groups: [{ group_id: 3, child_groups: [] }, { group_id: 4, child_groups: [group_id: 5, child_groups: []] }])
    end
  end

  describe ', group_level should return the height to given group at company structure' do
    it 'highest group level shoud eq 0' do
      expect(group_level(@g1)).to eq(0)
    end
    it 'g5 group level shoud eq 1' do
      expect(group_level(@g5)).to eq(2)
    end
    it 'g3 group level shoud eq 2' do
      expect(group_level(@g5)).to eq(2)
    end
  end

  describe 'groups_with_sizes' do
    groups_hash = nil
    before do
      groups_hash = [
        {'group_id' => 3, 'group_name' => 'g3', 'parent_id' => 1, 'num_of_emps' => 1},
        {'group_id' => 6, 'group_name' => 'g6', 'parent_id' => 2, 'num_of_emps' => 5},
        {'group_id' => 1, 'group_name' => 'g1', 'parent_id' => 0, 'num_of_emps' => 1},
        {'group_id' => 0, 'group_name' => 'g0', 'parent_id' => nil, 'num_of_emps' => 2},
        {'group_id' => 2, 'group_name' => 'g2', 'parent_id' => 0, 'num_of_emps' => 2},
        {'group_id' => 4, 'group_name' => 'g4', 'parent_id' => 1, 'num_of_emps' => 3},
        {'group_id' => 5, 'group_name' => 'g5', 'parent_id' => 2, 'num_of_emps' => 4},
      ]
    end

    it 'should create a data structure for the client' do
      res = CdsGroupsHelper.format_names_and_child_groups(groups_hash)
      res = res.sort_by { |g| g[:gid] }
      expect(res.length).to eq(groups_hash.length)
      expect(res[0][:depth]).to eq(0)
      expect(res[0][:accumulatedSize]).to eq(18)
      expect(res[0][:childrenIds]).to eq([1,2])
      expect(res[1][:depth]).to eq(1)
      expect(res[2][:accumulatedSize]).to eq(11)
      expect(res[2][:childrenIds]).to eq([5,6])
      expect(res[3][:depth]).to eq(2)
      expect(res[4][:accumulatedSize]).to eq(res[4][:size])
      expect(res[5][:childrenIds]).to eq([])
      expect(res.class).to eq(Array)
    end
  end
end
