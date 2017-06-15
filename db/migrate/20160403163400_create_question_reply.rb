class CreateQuestionReply < ActiveRecord::Migration
  def up
    create_table :question_replies do |t|
      t.integer :questionnaire_id
      t.integer :questionnaire_question_id
      t.integer :questionnaire_participant_id
      t.integer :reffered_questionnaire_participant_id
      t.boolean :answer

      t.timestamps null: false
    end
    add_index :question_replies, [:questionnaire_id],          name: 'index_question_replies_on_questionnaire_id'
    add_index :question_replies, [:questionnaire_question_id], name: 'index_question_replies_on_questionnaire_question_id'
    add_index :question_replies, [:questionnaire_participant_id],               name: 'index_question_replies_on_questionnaire_participant_id'
    add_index :question_replies, [:reffered_questionnaire_participant_id],      name: 'index_question_replies_on_reffered_questionnaire_participant_id'
  end

  def down
    drop_table :question_replies
  end
end
