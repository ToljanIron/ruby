class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.string :company
      t.string :password_digest
      t.string :remember_token

      t.timestamps null: true
    end
    add_index :users, :email, unique: true
    add_index :users, :remember_token
  end
end
