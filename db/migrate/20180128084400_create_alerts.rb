class CreateAlerts < ActiveRecord::Migration[5.1]
  def up
    create_table :alerts, force: :cascade do |t|
      t.integer :company_id, null: false
      t.integer :snapshot_id, null: false
      t.integer :employee_id
      t.integer :group_id
      t.integer :alert_type, null: false
      t.integer :company_metric_id
      t.integer :direction, null: false, default: 0
      t.integer :state, null: false, default: 0

      t.timestamps
    end

    add_index :alerts, [:company_id, :snapshot_id, :company_metric_id, :alert_type, :state, :group_id, :employee_id], name: 'index_alerts_main'
    add_index :alerts, [:group_id], name: 'index_alerts_groups'
    add_index :alerts, [:employee_id], name: 'index_alerts_employees'
  end

  def down
    drop_table :alerts
  end
end
