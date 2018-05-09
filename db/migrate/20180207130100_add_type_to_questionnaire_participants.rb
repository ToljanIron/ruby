class AddTypeToQuestionnaireParticipants < ActiveRecord::Migration[4.2]
  def up
    add_column :questionnaire_participants, :participant_type, :integer, default: 0
  end

  def down
    remove_column :questionnaire_participants, :participant_type
  end
end
