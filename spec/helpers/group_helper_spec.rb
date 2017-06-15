require 'spec_helper'

describe GroupsHelper, type: :helper do

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
      res = covert_formal_structure_to_group_id_child_groups_pairs @g1.id
      expect(res).to eq(group_id: 1, child_groups: [], selected: false)
    end

    it 'should return {group_id:id, child_groups:[...]} in recursive format' do
      res = covert_formal_structure_to_group_id_child_groups_pairs @g4.id
      expect(res).to eq(group_id: 4, child_groups: [{ group_id: 5, child_groups: [], selected: false}], selected: false)
    end

    it 'should return {group_id:id, child_groups:[...]} in recursive format' do
      res = covert_formal_structure_to_group_id_child_groups_pairs @g2.id
      expect(res).to eq(group_id: 2, child_groups: [{ group_id: 3, child_groups: [], selected: false }, { group_id: 4, child_groups: [group_id: 5, child_groups: [], selected: false], selected: false }], selected: false)
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
end
