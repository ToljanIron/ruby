class AddIndexToNetworkSnapshotNodes < ActiveRecord::Migration[4.2]
  def change
    add_index :network_snapshot_nodes, [:employee_from_id, :employee_to_id, :snapshot_id], name: 'index_snapshot_nodes_on_from_to_sid'
  end
end
