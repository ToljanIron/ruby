class AddSignificantLevelToEmailSnapshotData < ActiveRecord::Migration[4.2]
  def up
    add_column :email_snapshot_data, :significant_level, :integer
    add_column :email_snapshot_data, :above_median, :integer
  end

  def down
    remove_column :email_snapshot_data, :significant_level
    remove_column :email_snapshot_data, :above_median
  end
end
