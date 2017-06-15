class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :type_id, null: false
      t.integer :credential_id, null: false
      t.datetime :next_run, null: false
      t.integer :diff, null: false
      t.boolean :order_type, null: false

      t.timestamps
    end
  end
end
