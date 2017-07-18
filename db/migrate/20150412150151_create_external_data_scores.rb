class CreateExternalDataScores < ActiveRecord::Migration[4.2]
  def change
    create_table :external_data_scores do |t|
      t.decimal :score, null: false
      t.integer :external_data_metric_id, null: false
      t.integer :snapshot_id, null: false
      t.timestamps null: false
    end
  end
end
