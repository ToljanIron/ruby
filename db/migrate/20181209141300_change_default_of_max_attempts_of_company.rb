class ChangeDefaultOfMaxAttemptsOfCompany < ActiveRecord::Migration[5.1]
  def change
  	change_column :companies, :max_login_attempts, :integer, default: 10
  end
end
