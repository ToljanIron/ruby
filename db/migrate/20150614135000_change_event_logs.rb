class ChangeEventLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :event_logs, :event_type_id, :integer
    remove_column :event_logs, :company_id if column_exists?(:event_logs, :company_id)
    remove_column :event_logs, :event_type if column_exists?(:event_logs, :event_type)
  end
end
