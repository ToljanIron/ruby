class AddSnapshotIdToQuestionnaires < ActiveRecord::Migration[4.2]
  def up
    add_column :questionnaires, :snapshot_id, :integer, null: false, default: -1
  end

  def down
    remove_column :questionnaires, :snapshot_id
  end
end
