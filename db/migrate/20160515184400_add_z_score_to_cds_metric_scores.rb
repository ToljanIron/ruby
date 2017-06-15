class AddZScoreToCdsMetricScores < ActiveRecord::Migration
  def up
    add_column :cds_metric_scores, :z_score, :float
  end

  def down
    remove_column :cds_metric_scores, :z_score
  end
end
