class AddPrevQuestionnaireIdToQuestionnaires < ActiveRecord::Migration[4.2]
  def up
    add_column :questionnaires, :prev_questionnaire_id, :integer
  end

  def down
    remove_column :questionnaires, :prev_questionnaire_id
  end
end
