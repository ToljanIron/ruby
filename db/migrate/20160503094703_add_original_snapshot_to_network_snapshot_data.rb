class AddOriginalSnapshotToNetworkSnapshotData < ActiveRecord::Migration
  def change
  	add_column :network_snapshot_data, :original_snapshot_id, :integer
    update_current_data
  end

  def update_current_data
    NetworkSnapshotData.update_all('original_snapshot_id=snapshot_id')
  end
end
