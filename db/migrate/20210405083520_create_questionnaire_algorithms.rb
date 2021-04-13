class CreateQuestionnaireAlgorithms < ActiveRecord::Migration[5.2]
  def change
    create_table :questionnaire_algorithms do |t|
      t.integer :algorithm_type_id
      t.integer :employee_id
      t.integer :company_id
      t.integer :snapshot_id
      t.integer :network_id
      t.integer :questionnaire_id
      t.integer :questionnaire_question_id
      t.decimal :general_score
      t.decimal :group_score
      t.decimal :office_score
      t.decimal :gender_score
      t.decimal :rank_score

      t.timestamps
    end
  end
end
