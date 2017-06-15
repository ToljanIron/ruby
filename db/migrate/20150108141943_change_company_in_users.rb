class ChangeCompanyInUsers < ActiveRecord::Migration
  def change
    remove_column :users, :company
    add_column :users, :company_id, :integer
  end
end
