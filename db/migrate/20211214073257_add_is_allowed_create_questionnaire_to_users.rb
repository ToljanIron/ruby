class AddIsAllowedCreateQuestionnaireToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_allowed_create_questionnaire, :boolean, default: true
  end
end
