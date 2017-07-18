class CreateSnapshots < ActiveRecord::Migration[4.2]
  def change
    create_table :snapshots do |t|
      t.string :name
      t.integer :snapshot_type
      t.datetime :timestamp
      t.integer :company_id

      t.timestamps
    end
    add_index :snapshots, [:company_id],   name: 'index_snapshots_on_company_id'
  end
end
