class AddTypeToCompanyMetric < ActiveRecord::Migration
  def change
    add_column :company_metrics, :algorithm_type_id, :integer
  end
end
