require 'spec_helper'

describe WordCloudHelper, type: :helper do
  OVERLAY_ENTITY = 0
  EMPLOYEE = 1
  before do
    OverlayEntityType.find_or_create_by(id: 4, overlay_entity_type: 1, name: 'keywords', color_id: 2)
    o_e_group = OverlayEntityGroup.find_or_create_by(overlay_entity_type_id: 4, company_id: 1, name: 'All keywords')
    ov_1 = OverlayEntity.find_or_create_by(overlay_entity_type_id: 4, company_id: 1, overlay_entity_group_id: o_e_group.id, name: 'blah1')
    ov_2 = OverlayEntity.find_or_create_by(overlay_entity_type_id: 4, company_id: 1, overlay_entity_group_id: o_e_group.id, name: 'blah2')
    ov_3 = OverlayEntity.find_or_create_by(overlay_entity_type_id: 4, company_id: 1, overlay_entity_group_id: o_e_group.id, name: 'blah3')
    ov_4 = OverlayEntity.find_or_create_by(overlay_entity_type_id: 4, company_id: 1, overlay_entity_group_id: o_e_group.id, name: 'blah4')
    @g_1 = FactoryGirl.create(:group, name: 'parent_group', company_id: 1)
    @emp_1 = FactoryGirl.create(:employee, company_id: 1, group_id: @g_1.id)
    @emp_2 = FactoryGirl.create(:employee, company_id: 1, group_id: @g_1.id)
    @emp_3 = FactoryGirl.create(:employee, company_id: 1, group_id: @g_1.id)
    @emp_4 = FactoryGirl.create(:employee, company_id: 1, group_id: @g_1.id)
    @emp_5 = FactoryGirl.create(:employee, company_id: 1, group_id: @g_1.id)
    OverlaySnapshotData.find_or_create_by(snapshot_id: 1, from_id: ov_1.id, from_type: OVERLAY_ENTITY, to_id: @emp_1.id, to_type: EMPLOYEE, value: 5)
    OverlaySnapshotData.find_or_create_by(snapshot_id: 1, from_id: ov_1.id, from_type: OVERLAY_ENTITY, to_id: @emp_3.id, to_type: EMPLOYEE, value: 3)
    OverlaySnapshotData.find_or_create_by(snapshot_id: 1, from_id: ov_2.id, from_type: OVERLAY_ENTITY, to_id: @emp_1.id, to_type: EMPLOYEE, value: 10)
  end
  describe 'get_word_cloud_for_group' do
    it 'should return an empty object when there is not entites in snapshot' do
      res = WordCloudHelper.get_word_cloud_for_group(1, @g_1.id, 5)
      expect(res.count).to eq 0
      expect(res).to eql({})
    end
    it 'should return the words pet group per snapshot by count order ' do
      res = WordCloudHelper.get_word_cloud_for_group(1, @g_1.id, 1)
      expect(res.count).to eq 2
      expect(res['blah1']).to eq 8
      expect(res['blah2']).to eq 10
    end
  end
end
