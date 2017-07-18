class RemoveCompanyIdFromAlgorithm < ActiveRecord::Migration[4.2]
  def change
    remove_column :algorithms, :company_id, :integer
  end
end
