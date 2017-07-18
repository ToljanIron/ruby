class AddParamsToJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :params, :string
  end
end
