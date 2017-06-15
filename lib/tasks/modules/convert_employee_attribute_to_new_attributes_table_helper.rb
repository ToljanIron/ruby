module ConvertEmployeeAttributeToNewAttributesTableHelper
  def self.convert_employee_attributes
    EmployeeAttribute.all.each do |e|
      overlay_entity_type = OverlayEntityType.find_or_create_by(overlay_entity_type: e.data_type)
      c_id = Snapshot.where(id: e.snapshot_id).first.try(:company_id)
      OverlayEntityConfiguration.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: c_id)
      overlay_entity = OverlayEntity.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: c_id, name: e.data1)
      OverlaySnapshotData.find_or_create_by(snapshot_id: e.snapshot_id, from_id: e.employee_id, from_type_id: -1, to_id: overlay_entity.id, to_type_id: overlay_entity.overlay_entity_type_id)
    end
  end
end
