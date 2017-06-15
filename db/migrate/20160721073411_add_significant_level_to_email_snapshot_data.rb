class AddSignificantLevelToEmailSnapshotData < ActiveRecord::Migration
  include EmailSnapshotDataHelper
  def up
    add_column :email_snapshot_data, :significant_level, :integer
    add_column :email_snapshot_data, :above_median, :integer
    # EmailSnapshotDataHelper.calc_meaningfull_emails
  end

  def down
    remove_column :email_snapshot_data, :significant_level
    remove_column :email_snapshot_data, :above_median
  end
end
