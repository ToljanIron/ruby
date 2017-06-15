class ChangeJobsArchives < ActiveRecord::Migration
  def change
    remove_column :jobs_archives, :order_type
  end
end
