class AddIndexToCdsMetricScores < ActiveRecord::Migration
  def change
    add_index :cds_metric_scores, :company_metric_id
  end
end
