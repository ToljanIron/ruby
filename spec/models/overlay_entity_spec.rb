require 'spec_helper'

describe OverlayEntity, type: :model do
  before do
    @attributes_table = OverlayEntity.new
  end

  subject { @attributes_table }

  it { is_expected.to respond_to(:company_id) }
  it { is_expected.to respond_to(:overlay_entity_type_id) }
  it { is_expected.to respond_to(:overlay_entity_group_id) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:active) }

  describe 'with valid data should be valid' do
    it { is_expected.to be_valid }
  end

  describe 'connections' do
    before do
      @attributes_table.company_id = 1
      @attributes_table.overlay_entity_type_id = 1
      @attributes_table.save!
      @connection1 = OverlaySnapshotData.create(from_type: 'from_overlay_entity', from_id: @attributes_table.id, to_type: 'to_employee', to_id: 1, snapshot_id: 1)
      @connection2 = OverlaySnapshotData.create(from_type: 'from_overlay_entity', from_id: @attributes_table.id, to_type: 'to_employee', to_id: 2, snapshot_id: 1)
      @connection3 = OverlaySnapshotData.create(from_type: 'from_overlay_entity', from_id: 100, to_type: 'to_employee', to_id: 2, snapshot_id: 1)
      @connection4 = OverlaySnapshotData.create(to_type: 'to_overlay_entity', to_id: @attributes_table.id, from_type: 'from_employee', from_id: 1, snapshot_id: 1)
      @connection5 = OverlaySnapshotData.create(to_type: 'to_overlay_entity', to_id: @attributes_table.id, from_type: 'from_employee', from_id: 3, snapshot_id: 1)
      @connection6 = OverlaySnapshotData.create(to_type: 'to_overlay_entity', to_id: 100, from_type: 'from_employee', from_id: 3, snapshot_id: 1)
    end

    it 'should return connections from entity' do
      expect(@attributes_table.connections_from.length).to eq(2)
      expect(@attributes_table.connections_from).to include(@connection1)
      expect(@attributes_table.connections_from).to include(@connection2)
    end

    it 'should return connections to entity' do
      expect(@attributes_table.connections_to.length).to eq(2)
      expect(@attributes_table.connections_to).to include(@connection4)
      expect(@attributes_table.connections_to).to include(@connection5)
    end

    it 'should return connections from and to entity' do
      expect(@attributes_table.connections.length).to eq(4)
      expect(@attributes_table.connections).to include(@connection1)
      expect(@attributes_table.connections).to include(@connection2)
      expect(@attributes_table.connections).to include(@connection4)
      expect(@attributes_table.connections).to include(@connection5)
    end
  end
end
