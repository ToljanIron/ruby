class AddEmailInfoToNetworkSnapshotData < ActiveRecord::Migration
  def self.up
    add_column :network_snapshot_data, :message_id, :string
    add_column :network_snapshot_data, :multiplicity, :integer
    add_column :network_snapshot_data, :from_type, :integer
    add_column :network_snapshot_data, :to_type, :integer
    add_column :network_snapshot_data, :communication_date, :date
  end

  def self.down
    remove_column :network_snapshot_data, :message_id, :string
    remove_column :network_snapshot_data, :multiplicity, :integer
    remove_column :network_snapshot_data, :from_type, :integer
    remove_column :network_snapshot_data, :to_type, :integer
    remove_column :network_snapshot_data, :communication_date, :date
  end
end
