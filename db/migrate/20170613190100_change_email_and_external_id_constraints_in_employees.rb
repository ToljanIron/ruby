class ChangeEmailAndExternalIdConstraintsInEmployees < ActiveRecord::Migration
  def change
    remove_index :employees, :email
    remove_index :employees, :external_id

    add_index :employees, [:email],               name: 'index_employees_on_email',                 unique: false
    add_index :employees, [:email, :snapshot_id], name: 'index_employees_on_email_and_snapshot_id', unique: true

    add_index :employees, [:external_id], name: 'index_employees_on_external_id',                               unique: false
    add_index :employees, [:external_id, :snapshot_id], name: 'index_employees_on_external_id_and_snapshot_id', unique: true
  end
end
