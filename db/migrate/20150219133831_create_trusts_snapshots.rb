class CreateTrustsSnapshots < ActiveRecord::Migration
  def change
    create_table :trusts_snapshots do |t|
      t.integer :employee_id, null: false
      t.integer :trusted_id, null: false
      t.integer :snapshot_id, null: false
      t.integer :trust_flag, default: 0

      t.timestamps null: false
    end
    add_index :trusts_snapshots, :employee_id
    add_index :trusts_snapshots, :trusted_id
  end
end
