class CreateMetricScores < ActiveRecord::Migration
  def change
    return if table_exists? 'metric_scores'
    create_table :metric_scores do |t|
      t.integer :company_id,                    null: false
      t.integer :employee_id,                   null: false
      t.integer :pin_id
      t.integer :group_id
      t.integer :snapshot_id,                   null: false
      t.integer :metric_id,                     null: false
      t.decimal :score, precision: 4, scale: 2, null: false
    end
  end
end
