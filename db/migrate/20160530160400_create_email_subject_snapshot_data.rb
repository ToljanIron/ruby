class CreateEmailSubjectSnapshotData < ActiveRecord::Migration
  def up
    create_table :email_subject_snapshot_data do |t|
      t.integer :employee_from_id, null: false
      t.integer :employee_to_id,   null: false
      t.integer :snapshot_id,      null: false
      t.string  :subject
    end
    add_index :email_subject_snapshot_data, [:employee_from_id, :employee_to_id, :snapshot_id],    name: 'index_email_subject_snapshot_data'
  end

  def down
    drop_table :email_subject_snapshot_data
  end
end
