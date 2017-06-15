class ChangeTableNameNetworkSnapshotNodestoEmailSnapshotData < ActiveRecord::Migration
  def change
    rename_table :network_snapshot_nodes, :email_snapshot_data
  end
end
