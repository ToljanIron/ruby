class AddAlgorithmIdToCdsMetricScores < ActiveRecord::Migration[4.2]
  def change
    add_column :cds_metric_scores, :algorithm_id, :integer
  end
end
