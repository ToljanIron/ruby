class RemoveExternalIdUniqeIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index  :employees, [:external_id]
    add_index     :employees, [:external_id], name: 'index_employees_on_external_id'
  end
end
