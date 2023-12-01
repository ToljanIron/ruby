class AddWasSnowballedByToQuestionnaireParticipants < ActiveRecord::Migration[6.1]
  def change
    add_column :questionnaire_participants, :snowballer_employee_id, :integer
  end
end
