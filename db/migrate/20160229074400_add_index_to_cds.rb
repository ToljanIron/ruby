class AddIndexToCds < ActiveRecord::Migration
  def change
    return unless table_exists? 'cds_metric_scores'
    add_index :cds_metric_scores, :company_id, name: 'index_cds_metric_scores_on_company_id'
    add_index :cds_metric_scores, :employee_id, name: 'index_cds_metric_scores_on_employee_id'
    add_index :cds_metric_scores, :pin_id, name: 'index_cds_metric_scores_on_pin_id'
    add_index :cds_metric_scores, :group_id, name: 'index_cds_metric_scores_on_group_id'
    add_index :cds_metric_scores, :snapshot_id, name: 'index_cds_metric_scores_on_snapshot_id'
    add_index :cds_metric_scores, :algorithm_id, name: 'index_cds_metric_scores_on_algorithm_id'
  end
end

