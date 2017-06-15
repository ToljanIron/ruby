require 'spec_helper'

describe OverlayEntityGroup, type: :model do
  before do
    @attribute_group = OverlayEntityGroup.new
  end

  subject { @attribute_group }

  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:company_id) }

  describe 'with invalid data should be invalid' do
    it { is_expected.to be_valid }
  end

  describe 'num_of_connections' do
    before do
      @attribute_group.company_id = 1
      @attribute_group.overlay_entity_type_id = 1
      @attribute_group.save!
      @entity1 = OverlayEntity.create(company_id: 1, overlay_entity_type_id: 1, overlay_entity_group_id: @attribute_group.id)
      @entity2 = OverlayEntity.create(company_id: 1, overlay_entity_type_id: 1, overlay_entity_group_id: @attribute_group.id)
      OverlaySnapshotData.create(from_type: 'from_overlay_entity', from_id: @entity1.id, to_type: 'to_employee', to_id: 1, snapshot_id: 1)
      OverlaySnapshotData.create(from_type: 'from_overlay_entity', from_id: @entity2.id, to_type: 'to_employee', to_id: 2, snapshot_id: 1)
      OverlaySnapshotData.create(from_type: 'from_overlay_entity', from_id: 100, to_type: 'to_employee', to_id: 2, snapshot_id: 1)
      OverlaySnapshotData.create(to_type: 'to_overlay_entity', to_id: @entity1.id, from_type: 'from_employee', from_id: 1, snapshot_id: 1)
      OverlaySnapshotData.create(to_type: 'to_overlay_entity', to_id: @entity2.id, from_type: 'from_employee', from_id: 3, snapshot_id: 1)
      OverlaySnapshotData.create(to_type: 'to_overlay_entity', to_id: 100, from_type: 'from_employee', from_id: 3, snapshot_id: 1)
    end

    it 'should return a sum of numbers of connections for each element of group' do
      expect(@attribute_group.num_of_connections).to eq(4)
    end
  end
end
