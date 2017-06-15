class AddStatusToQuestionnaireParticipants < ActiveRecord::Migration
  def up
    add_column :questionnaire_participants, :status, :integer, default: 0
  end

  def down
    remove_column :questionnaire_participants, :status
  end
end
