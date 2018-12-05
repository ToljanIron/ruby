class AddLanguagesToQuestionnaire < ActiveRecord::Migration[5.1]
  def up
    add_column :questionnaires, :email_subject2, :string
    add_column :questionnaires, :email_subject3, :string
    add_column :questionnaires, :email_text2, :string
    add_column :questionnaires, :email_text3, :string
  end

  def down
    remove_column :questionnaires, :email_subject2
    remove_column :questionnaires, :email_subject3
    remove_column :questionnaires, :email_text2
    remove_column :questionnaires, :email_text3
  end
end
