class CreateCdsMetricScore < ActiveRecord::Migration[4.2]
  def change
    return if table_exists? 'cds_metric_scores'
    create_table :cds_metric_scores do |t|
      t.integer :company_id,                     null: false
      t.integer :employee_id,                   null: false
      t.integer :pin_id
      t.integer :group_id
      t.integer :snapshot_id,                   null: false
      t.integer :company_metric_id,            null: false
      t.decimal :score, precision: 4, scale: 2, null: false
    end
  end
end
