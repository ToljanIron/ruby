class RemoveExternalIdUniqeIndex < ActiveRecord::Migration
  def change
    remove_index  :employees, [:external_id]
    add_index     :employees, [:external_id], name: 'index_employees_on_external_id'
  end
end
