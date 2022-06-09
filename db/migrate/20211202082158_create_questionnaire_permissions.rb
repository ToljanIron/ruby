class CreateQuestionnairePermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :questionnaire_permissions do |t|
      t.integer :user_id
      t.integer :company_id 
      t.integer :questionnaire_id

      t.timestamps
    end
  end
end
