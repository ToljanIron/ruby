class CreateQuestionnaireParticipants < ActiveRecord::Migration[4.2]
  def up
    create_table :questionnaire_participants do |t|
      t.integer :employee_id
      t.integer :questionnaire_id
      t.string  :token
      t.integer :current_questiannair_question_id
      t.boolean :in_continue_later_status, default: false
      t.boolean :active, default: true
    end
  end

  def down
    drop_table :questionnaire_participants
  end
end
