class AddLanguageToQuestionnaires < ActiveRecord::Migration
  def change
    add_column :questionnaires, :language_id, :integer
  end
end
