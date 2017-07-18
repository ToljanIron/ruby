class AddGaugeIdToCompanyMetric < ActiveRecord::Migration[4.2]
  def change
    add_column :company_metrics, :gauge_id, :integer, null: true
  end
end
