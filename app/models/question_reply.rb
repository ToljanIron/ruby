class QuestionReply < ActiveRecord::Base
  belongs_to :questionnaire_question
  belongs_to :employee
end
