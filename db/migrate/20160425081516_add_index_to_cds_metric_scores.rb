class AddIndexToCdsMetricScores < ActiveRecord::Migration[4.2]
  def change
    add_index :cds_metric_scores, :company_metric_id
  end
end
