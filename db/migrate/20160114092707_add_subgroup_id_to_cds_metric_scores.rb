class AddSubgroupIdToCdsMetricScores < ActiveRecord::Migration
  def change
    return unless table_exists? 'metric_scores'
    add_column :cds_metric_scores, :subgroup_id, :integer
    add_index :cds_metric_scores, :subgroup_id, name: 'index_cds_metric_scores_on_subgroup_id'
  end
end
