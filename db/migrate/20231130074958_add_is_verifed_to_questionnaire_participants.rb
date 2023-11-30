class AddIsVerifedToQuestionnaireParticipants < ActiveRecord::Migration[6.1]
  def change
    add_column :questionnaire_participants, :is_verified, :bool, default: true
  end
end
