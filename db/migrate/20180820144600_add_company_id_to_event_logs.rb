class AddCompanyIdToEventLogs < ActiveRecord::Migration[5.1]
  def up
    add_column :event_logs, :company_id, :integer, default: nil
  end

  def down
    remove_column :event_logs, :company_id
  end
end
