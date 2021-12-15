class AddLevelToQuestionnairePermission < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaire_permissions, :level, :integer
  end
end
