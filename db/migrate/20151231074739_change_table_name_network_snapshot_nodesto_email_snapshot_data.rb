class ChangeTableNameNetworkSnapshotNodestoEmailSnapshotData < ActiveRecord::Migration[4.2]
  def change
    rename_table :network_snapshot_nodes, :email_snapshot_data
  end
end
