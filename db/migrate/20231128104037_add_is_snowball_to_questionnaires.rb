class AddIsSnowballToQuestionnaires < ActiveRecord::Migration[6.1]
  def change
    add_column :questionnaires, :is_snowball_q, :bool, default: false
  end
end
