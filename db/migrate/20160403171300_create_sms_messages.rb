class CreateSmsMessages < ActiveRecord::Migration
  def up
    create_table :sms_messages do |t|
      t.integer :questionnaire_participant_id
      t.boolean :pending, default: false
      t.datetime :sent_at
      t.text :message

      t.timestamps null: false
    end
    add_index :sms_messages, [:questionnaire_participant_id],    name: 'index_sms_messages_on_questionnaire_participant_id'
  end

  def down
    drop_table :sms_messages
  end
end