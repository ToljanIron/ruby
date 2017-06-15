class CreateCompanyMetrics < ActiveRecord::Migration
  def change
    create_table :company_metrics do |t|
      t.integer :company_id
      t.integer :network_id
      t.integer :metric_id
      t.integer :algorithm_id
      t.string :algorithm_params
    end
  end
end
