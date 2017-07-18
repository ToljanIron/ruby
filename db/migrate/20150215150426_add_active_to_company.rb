class AddActiveToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :active, :boolean, default: true
  end
end
