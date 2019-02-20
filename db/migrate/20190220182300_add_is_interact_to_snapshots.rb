class AddIsInteractToSnapshots < ActiveRecord::Migration[5.1]
  def up
    add_column :snapshots, :is_interact, :boolean, default: false
  end

  def down
    remove_column :snapshots, :is_interact
  end
end
