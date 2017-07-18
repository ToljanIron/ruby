class ChangeJobsArchives < ActiveRecord::Migration[4.2]
  def change
    remove_column :jobs_archives, :order_type
  end
end
