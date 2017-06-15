class AddSubgroupIdToMetricScores < ActiveRecord::Migration
  def change
    return unless table_exists? 'metric_scores'
    add_column :metric_scores, :subgroup_id, :integer
    add_index :metric_scores, :subgroup_id, name: 'index_metric_scores_on_subgroup_id'
  end
end
