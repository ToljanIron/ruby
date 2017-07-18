class CreateMetrics < ActiveRecord::Migration[4.2]
  def change
    return if table_exists? 'metrics'
    create_table :metrics do |t|
      t.string :name,        null: false
      t.string :metric_type, null: false
      t.integer :index,      null: false
    end
  end
end
