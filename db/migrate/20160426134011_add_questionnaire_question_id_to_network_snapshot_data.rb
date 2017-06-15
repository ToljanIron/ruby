class AddQuestionnaireQuestionIdToNetworkSnapshotData < ActiveRecord::Migration
  def change
    add_column :network_snapshot_data, :questionnaire_question_id, :integer
    update_old_data
  end

  def update_old_data
    NetworkSnapshotData.update_all(questionnaire_question_id: -1)
  end
end
