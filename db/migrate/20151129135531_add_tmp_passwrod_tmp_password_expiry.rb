class AddTmpPasswrodTmpPasswordExpiry < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :tmp_password, :string
    add_column :users, :tmp_password_expiry, :timestamp
  end
end
