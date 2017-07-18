class ChangeCompanyInUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :company
    add_column :users, :company_id, :integer
  end
end
