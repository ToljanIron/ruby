class CdsMetricScoresAddNumeratorDenominatorParam1Param2Columns < ActiveRecord::Migration[5.1]
  def change
  	add_column :cds_metric_scores, :numerator, :decimal, precision: 10, scale: 2, default: nil unless column_exists? :cds_metric_scores, :numerator
  	add_column :cds_metric_scores, :denominator, :decimal, precision: 10, scale: 2,  default: nil unless column_exists? :cds_metric_scores, :denominator
  	add_column :cds_metric_scores, :param1, :decimal, precision: 10, scale: 2, default: nil unless column_exists? :cds_metric_scores, :param1
  	add_column :cds_metric_scores, :param2, :decimal, precision: 10, scale: 2, default: nil unless column_exists? :cds_metric_scores, :param2
  end
end
