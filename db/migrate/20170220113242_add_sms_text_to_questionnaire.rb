class AddSmsTextToQuestionnaire < ActiveRecord::Migration
  def change
    add_column :questionnaires, :sms_text, :string
  end
end
