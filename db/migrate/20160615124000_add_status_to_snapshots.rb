class AddStatusToSnapshots < ActiveRecord::Migration
  def up
    add_column :snapshots, :status, :integer, default: 2
  end

  def down
    remove_column :snapshots, :status
  end
end
