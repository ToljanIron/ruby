class ChangeJobsQueues < ActiveRecord::Migration[4.2]
  def change
    remove_column :jobs_queues, :order_type
    remove_column :jobs_queues, :running
  end
end
