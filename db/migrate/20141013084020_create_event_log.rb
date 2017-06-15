class CreateEventLog < ActiveRecord::Migration
  def change
    create_table :event_logs do |t|
      t.integer :event_type, null: false
      t.integer :company_id
      t.string :message
      t.integer :job_id
      t.timestamps
    end
  end
end
