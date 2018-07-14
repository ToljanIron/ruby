class AddQuestionnaireIdToGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :groups, :questionnaire_id, :integer
  end

  def down
    remove_column :groups, :questionnaire_id
  end
end
