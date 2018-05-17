class AddSessionTimeoutPasswordUpdateTimeLoginAttmeptsCompanyTable < ActiveRecord::Migration[5.1]
  def change
  	add_column :companies, :session_timeout, :integer, default: 3  unless column_exists? :companies, :session_timeout
  	add_column :companies, :password_update_interval, :integer, default: 1  unless column_exists? :companies, :password_update_interval
  	add_column :companies, :max_login_attempts, :integer, default: 0  unless column_exists? :companies, :max_login_attempts
  end
end
