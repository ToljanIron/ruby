class AddStatusToSnapshots < ActiveRecord::Migration[4.2]
  def up
    add_column :snapshots, :status, :integer, default: 2
  end

  def down
    remove_column :snapshots, :status
  end
end
