class AddActiveToCompanyMetrics < ActiveRecord::Migration
  def up
    add_column :company_metrics, :active, :boolean, default: true
  end

  def down
    remove_column :company_metrics, :active
  end
end
