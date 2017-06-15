class AddLastSnapshotIdToQuestionnaire < ActiveRecord::Migration
  def change
    add_column :questionnaires, :last_snapshot_id, :integer
  end
end
