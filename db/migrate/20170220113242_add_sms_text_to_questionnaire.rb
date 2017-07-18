class AddSmsTextToQuestionnaire < ActiveRecord::Migration[4.2]
  def change
    add_column :questionnaires, :sms_text, :string
  end
end
