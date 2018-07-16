class AddIsFunnelQuestion < ActiveRecord::Migration[4.2]
  def up
    add_column :questions, :is_funnel_question, :boolean, default: false
    add_column :questionnaire_questions, :is_funnel_question, :boolean, default: false
  end

  def down
    remove_column :questions, :is_funnel_question
    remove_column :questionnaire_questions, :is_funnel_question

  end
end
