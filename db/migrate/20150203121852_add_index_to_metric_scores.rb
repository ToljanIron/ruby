class AddIndexToMetricScores < ActiveRecord::Migration
  def change
    return unless table_exists? 'metric_scores'
    add_index :metric_scores, :company_id, name: 'index_metric_scores_on_company_id'
    add_index :metric_scores, :employee_id, name: 'index_metric_scores_on_employee_id'
    add_index :metric_scores, :pin_id, name: 'index_metric_scores_on_pin_id'
    add_index :metric_scores, :group_id, name: 'index_metric_scores_on_group_id'
    add_index :metric_scores, :snapshot_id, name: 'index_metric_scores_on_snapshot_id'
    add_index :metric_scores, :metric_id, name: 'index_metric_scores_on_metric_id'
  end
end
