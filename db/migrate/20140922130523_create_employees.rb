class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      # mandtory
      t.integer :company_id,  null: false
      t.string  :email,       null: false
      t.string  :external_id, null: false
      t.string  :first_name,  null: false
      t.string  :last_name,   null: false

      # optional
      t.datetime  :date_of_birth
      t.integer   :employment
      t.integer   :gender
      t.integer   :group_id
      t.string    :home_address
      t.integer   :job_title_id
      t.integer   :marital_status_id
      t.string    :middle_name
      t.integer   :position_scope
      t.integer   :qualifications
      t.integer   :rank_id
      t.integer   :role_id
      t.integer   :office_id
      t.datetime  :work_start_date

      # for system use only
      t.string    :img_url
      t.datetime  :img_url_last_updated, default: 1.day.ago
      t.integer   :color_id

      t.timestamps
    end
    add_index :employees, [:group_id],    name: 'index_employees_on_group_id'
    add_index :employees, [:email],       name: 'index_employees_on_email',       unique: true
    add_index :employees, [:external_id], name: 'index_employees_on_external_id', unique: true
  end
end
