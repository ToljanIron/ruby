class RemoveCompanyIdFromAlgorithm < ActiveRecord::Migration
  def change
    remove_column :algorithms, :company_id, :integer
  end
end
