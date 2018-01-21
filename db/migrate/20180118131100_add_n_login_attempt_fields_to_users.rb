class AddNLoginAttemptFieldsToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :number_of_recent_login_attempts,  :integer, default: 0
    add_column :users, :time_of_last_login_attempt, :timestamp, default: nil
    add_column :users, :is_locked_due_to_max_attempts, :boolean, default: false
  end

  def down
    remove_column :users, :number_of_recent_login_attempts
    remove_column :users, :time_of_last_login_attempt
    remove_column :users, :is_locked_due_to_max_attempts
  end
end
