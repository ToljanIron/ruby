class AddCompletedTimeforQuestionnaires < ActiveRecord::Migration[4.2]
  def change
    add_column :questionnaires, :completed_at, :datetime
  end
end
