class CreateEmailMessages < ActiveRecord::Migration[4.2]
  def up
    create_table :email_messages do |t|
      t.integer :questionnaire_participant_id
      t.boolean :pending, default: false
      t.datetime :sent_at
      t.text :message

      t.timestamps null: false
    end
    add_index :email_messages, [:questionnaire_participant_id],    name: 'index_email_messages_on_questionnaire_participant_id'
  end
  def down
    drop_table :email_messages
  end
end