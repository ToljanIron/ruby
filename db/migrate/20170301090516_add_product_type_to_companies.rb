class AddProductTypeToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :product_type, :integer, default: 0
  end
end
