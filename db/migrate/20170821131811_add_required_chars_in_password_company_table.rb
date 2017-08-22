class AddRequiredCharsInPasswordCompanyTable < ActiveRecord::Migration[5.1]
  def change
  	add_column :companies, :required_chars_in_password, :string unless column_exists? :companies, :required_chars_in_password
  end
end
