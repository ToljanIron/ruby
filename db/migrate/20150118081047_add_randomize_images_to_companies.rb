class AddRandomizeImagesToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :randomize_image, :boolean , :default => false
  end
end
