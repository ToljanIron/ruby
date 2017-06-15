class CreateExternalDataMetrics < ActiveRecord::Migration
  def change
    create_table :external_data_metrics do |t|
      t.string :external_metric_name
      t.integer :company_id, null: false
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
