class AddLanguagesToQuestionnaireQuestions < ActiveRecord::Migration[4.2]
  def up
    add_column :questionnaire_questions, :title2, :string
    add_column :questionnaire_questions, :title3, :string
    add_column :questionnaire_questions, :body2, :text
    add_column :questionnaire_questions, :body3, :text
  end

  def down
    remove_column :questionnaire_questions, :title2
    remove_column :questionnaire_questions, :title3
    remove_column :questionnaire_questions, :body2
    remove_column :questionnaire_questions, :body3
  end
end
