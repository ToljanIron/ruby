class AddParamsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :params, :string
  end
end
