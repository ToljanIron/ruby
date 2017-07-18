class AddRandomizeImagesToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :randomize_image, :boolean , :default => false
  end
end
