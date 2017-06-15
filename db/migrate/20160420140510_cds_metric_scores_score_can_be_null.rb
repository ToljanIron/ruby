class CdsMetricScoresScoreCanBeNull < ActiveRecord::Migration
  def change
    # change_table :cds_metric_scores do |t|
    #   t.change :score, null: true
    # end
    change_column(:cds_metric_scores, :score, :decimal, precision: 4, scale: 2, null: true)
  end
end
