class CreateCredential < ActiveRecord::Migration[4.2]
  def change
    create_table :credentials do |t|
      t.integer :company_id, null: false
      t.string :user
      t.string :password_digest
      t.string :api_key
      t.timestamps
    end
  end
end
