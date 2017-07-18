class AddLastSnapshotIdToQuestionnaire < ActiveRecord::Migration[4.2]
  def change
    add_column :questionnaires, :last_snapshot_id, :integer
  end
end
