class AddTmpPasswrodTmpPasswordExpiry < ActiveRecord::Migration
  def change
    add_column :users, :tmp_password, :string
    add_column :users, :tmp_password_expiry, :timestamp
  end
end
