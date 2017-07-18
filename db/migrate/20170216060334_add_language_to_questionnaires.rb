class AddLanguageToQuestionnaires < ActiveRecord::Migration[4.2]
  def change
    add_column :questionnaires, :language_id, :integer
  end
end
