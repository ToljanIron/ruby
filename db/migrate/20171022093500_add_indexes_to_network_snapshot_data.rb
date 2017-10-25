class AddIndexesToNetworkSnapshotData < ActiveRecord::Migration[4.2]
  def change
    add_index :network_snapshot_data, [:from_employee_id, :to_employee_id, :snapshot_id], name: 'index_snapshot_nodes_on_from_to_sid'
    add_index :network_snapshot_data, [:from_employee_id], name: 'index_snapshot_nodes_on_from'
    add_index :network_snapshot_data, [:to_employee_id], name: 'index_snapshot_nodes_on_to'
    add_index :network_snapshot_data, [:snapshot_id], name: 'index_snapshot_nodes_on_sid'
    add_index :network_snapshot_data, [:multiplicity], name: 'index_snapshot_nodes_on_multiplicity'
    add_index :network_snapshot_data, [:from_type], name: 'index_snapshot_nodes_on_from_type'
    add_index :network_snapshot_data, [:to_type], name: 'index_snapshot_nodes_on_to_type'
  end
end
