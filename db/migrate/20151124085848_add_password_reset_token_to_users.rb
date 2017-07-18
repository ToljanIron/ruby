class AddPasswordResetTokenToUsers < ActiveRecord::Migration[4.2]
  def change
  	add_column :users, :password_reset_token, :string
  	add_column :users, :password_reset_token_expiry, :timestamp
	  add_index :users, :password_reset_token
  end
end
