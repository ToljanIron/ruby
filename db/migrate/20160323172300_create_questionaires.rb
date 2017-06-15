class CreateQuestionaires < ActiveRecord::Migration
  def up
    create_table :questionnaires do |t|
      t.integer :company_id, null: false
      t.integer :state, default: 0
      t.string  :name, null: false
      t.timestamp :sent_date
      t.string  :pending_send

      t.timestamps null: false
    end
    add_index :questionnaires, [:company_id, :name],  name: 'index_questionnaires_on_company_id', unique: true
  end

  def down
    drop_table :questionnaires
  end
end
