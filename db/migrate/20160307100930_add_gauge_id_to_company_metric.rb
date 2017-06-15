class AddGaugeIdToCompanyMetric < ActiveRecord::Migration
  def change
    add_column :company_metrics, :gauge_id, :integer, null: true
  end
end
