class CreateQuestionnaireQuestions < ActiveRecord::Migration[4.2]
  def up
    create_table :questionnaire_questions do |t|
      t.integer :company_id
      t.integer :questionnaire_id
      t.integer :question_id
      t.integer :network_id
      t.string  :title
      t.text    :body
      t.integer :order
      t.integer :depends_on_question
      t.integer :min
      t.integer :max
      t.boolean :active
    end
  end

  def down
    drop_table :questionnaire_questions
  end
end