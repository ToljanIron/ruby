class ChangeJobs < ActiveRecord::Migration[4.2]
  def change
    remove_column :jobs, :type_id
    remove_column :jobs, :credential_id
    remove_column :jobs, :diff
    remove_column :jobs, :order_type

    add_column :jobs, :name,            :string
    add_column :jobs, :company_id,      :integer
    add_column :jobs, :reoccurrence_id, :integer
    add_column :jobs, :type_number,     :integer
  end
end
