class AddLanguageToQuestionnaireParticipants < ActiveRecord::Migration[5.1]
  def up
    add_column :questionnaire_participants, :language_id, :integer, default: 1
  end

  def down
    remove_column :questionnaire_participants, :language_id
  end
end
