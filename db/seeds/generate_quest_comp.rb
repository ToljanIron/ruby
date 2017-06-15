Group.where(company_id: 9).delete_all
NetworkSnapshotData.where(snapshot_id: 74).delete_all
OverlayEntityGroup.where(company_id: 9).delete_all
OverlayEntity.where(company_id: 9).delete_all
OverlaySnapshotData.where(snapshot_id: 74).delete_all
OverlayEntityConfiguration.where(company_id: 9).delete_all


g1 = Group.create!(name: 'QC',  company_id: 9, color_id: 1)
g2 = Group.create!(name: 'G1',  company_id: 9, color_id: 3, parent_group_id: g1.id)
g3 = Group.create!(name: 'G2',  company_id: 9, color_id: 5, parent_group_id: g1.id)
g4 = Group.create!(name: 'G3',  company_id: 9, color_id: 7, parent_group_id: g1.id)
g5 = Group.create!(name: 'G31', company_id: 9, color_id: 9, parent_group_id: g4.id)

Employee.find(650).update(group_id: g2.id)
Employee.find(651).update(group_id: g2.id)
Employee.find(648).update(group_id: g3.id)
Employee.find(649).update(group_id: g3.id)
Employee.find(652).update(group_id: g4.id)
Employee.find(653).update(group_id: g5.id)

NetworkSnapshotData.create_email_adapter(employee_from_id: 650, employee_to_id: 651, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 650, employee_to_id: 648, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 651, employee_to_id: 652, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 648, employee_to_id: 651, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 648, employee_to_id: 650, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 648, employee_to_id: 653, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 648, employee_to_id: 652, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 649, employee_to_id: 648, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 652, employee_to_id: 653, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 652, employee_to_id: 650, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 653, employee_to_id: 649, n1: 1, significant_level: 3, snapshot_id: 74)
NetworkSnapshotData.create_email_adapter(employee_from_id: 653, employee_to_id: 651, n1: 1, significant_level: 3, snapshot_id: 74)

NetworkSnapshotData.create!(snapshot_id: 74, network_id: 40, company_id: 9, from_employee_id: 650, to_employee_id: 648, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 40, company_id: 9, from_employee_id: 651, to_employee_id: 649, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 40, company_id: 9, from_employee_id: 649, to_employee_id: 648, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 40, company_id: 9, from_employee_id: 648, to_employee_id: 652, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 40, company_id: 9, from_employee_id: 648, to_employee_id: 653, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 40, company_id: 9, from_employee_id: 652, to_employee_id: 653, value: 1)

NetworkSnapshotData.create!(snapshot_id: 74, network_id: 41, company_id: 9, from_employee_id: 650, to_employee_id: 649, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 41, company_id: 9, from_employee_id: 651, to_employee_id: 649, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 41, company_id: 9, from_employee_id: 652, to_employee_id: 652, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 41, company_id: 9, from_employee_id: 653, to_employee_id: 652, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 41, company_id: 9, from_employee_id: 648, to_employee_id: 653, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 41, company_id: 9, from_employee_id: 649, to_employee_id: 653, value: 1)
NetworkSnapshotData.create!(snapshot_id: 74, network_id: 41, company_id: 9, from_employee_id: 649, to_employee_id: 653, value: 1)

og1 = OverlayEntityGroup.create!(company_id: 9, name: 'Animanls', overlay_entity_type_id: 2)
og2 = OverlayEntityGroup.create!(company_id: 9, name: 'ynet.com', overlay_entity_type_id: 1)

a1 = OverlayEntity.create!(company_id: 9, overlay_entity_type_id: 2, overlay_entity_group_id: og1.id, name: 'Dog', active: true)
a2 = OverlayEntity.create!(company_id: 9, overlay_entity_type_id: 2, overlay_entity_group_id: og1.id, name: 'Cat', active: true)
a3 = OverlayEntity.create!(company_id: 9, overlay_entity_type_id: 2, overlay_entity_group_id: og1.id, name: 'Rat', active: true)

a4 = OverlayEntity.create!(company_id: 9, overlay_entity_type_id: 1, overlay_entity_group_id: og2.id, name: 'aa@acme.com', active: true)
a5 = OverlayEntity.create!(company_id: 9, overlay_entity_type_id: 1, overlay_entity_group_id: og2.id, name: 'bb@acme.com', active: true)

OverlaySnapshotData.create!(snapshot_id: 74, from_type: 1, from_id: 650, to_id: a1.id,to_type: 0, value: 1)
OverlaySnapshotData.create!(snapshot_id: 74, from_type: 1, from_id: 651, to_id: a2.id,to_type: 0, value: 1)
OverlaySnapshotData.create!(snapshot_id: 74, from_type: 1, from_id: 652, to_id: a3.id,to_type: 0, value: 1)
OverlaySnapshotData.create!(snapshot_id: 74, from_type: 1, from_id: 653, to_id: a1.id,to_type: 0, value: 1)

OverlaySnapshotData.create!(snapshot_id: 74, from_type: 1, from_id: 648, to_id: a4.id,to_type: 0, value: 1)
OverlaySnapshotData.create!(snapshot_id: 74, from_type: 1, from_id: 649, to_id: a5.id,to_type: 0, value: 1)

OverlayEntityConfiguration.create!(company_id: 9, overlay_entity_type_id: 1, active: true)
OverlayEntityConfiguration.create!(company_id: 9, overlay_entity_type_id: 2, active: true)
