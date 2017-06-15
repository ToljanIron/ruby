class AddProductTypeToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :product_type, :integer, default: 0
  end
end
