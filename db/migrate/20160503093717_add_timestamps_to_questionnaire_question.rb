class AddTimestampsToQuestionnaireQuestion < ActiveRecord::Migration
  def self.up
  	change_table :questionnaire_questions do |t|
  		t.timestamps
  	end
  end

  def self.down
    remove_column :questionnaire_questions, :created_at
    remove_column :questionnaire_questions, :updated_at
  end
end