class CreateNetworkSnapshotData < ActiveRecord::Migration
  def change
    create_table :network_snapshot_data do |t|
      t.integer 'snapshot_id', null: false
      t.integer 'network_id', null: false
      t.integer 'company_id', null: false
      t.integer 'from_employee_id', null: false
      t.integer 'to_employee_id', null: false
      t.integer 'value', null: false
    end
  end
end
