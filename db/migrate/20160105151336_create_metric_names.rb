class CreateMetricNames < ActiveRecord::Migration
  def change
    create_table :metric_names do |t|
      t.string 'name', null: false
      t.integer 'company_id', null: false
      t.timestamps
    end
  end
end
