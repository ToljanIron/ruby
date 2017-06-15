class CreateEmployeeAliasEmails < ActiveRecord::Migration
  def change
    create_table :employee_alias_emails do |t|
      t.string :email_alias, 	null: false
      t.integer :employee_id, null: false

      t.timestamps
    end
  end
end
