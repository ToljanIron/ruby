class AddQuestionnaireIdToNetworkNames < ActiveRecord::Migration[4.2]
  def up
    add_column :network_names, :questionnaire_id, :integer, null: false, default: -1
  end

  def down
    remove_column :network_names, :questionnaire_id
  end
end
