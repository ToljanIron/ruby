class AddTypeToCompanyMetric < ActiveRecord::Migration[4.2]
  def change
    add_column :company_metrics, :algorithm_type_id, :integer
  end
end
