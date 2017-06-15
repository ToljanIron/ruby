class AddCompletedTimeforQuestionnaires < ActiveRecord::Migration
  def change
    add_column :questionnaires, :completed_at, :datetime
  end
end
