class AddAlgorithmIdToCdsMetricScores < ActiveRecord::Migration
  def change
    add_column :cds_metric_scores, :algorithm_id, :integer
  end
end
