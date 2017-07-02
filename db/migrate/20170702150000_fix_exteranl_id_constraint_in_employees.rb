class FixExteranlIdConstraintInEmployees < ActiveRecord::Migration
  def up
    remove_index :employees, [:external_id, :snapshot_id]
    add_index :employees, [:external_id, :snapshot_id, :company_id], name: 'index_employees_on_ext_and_snapshot_id_and_company_id', unique: true
  end
end
