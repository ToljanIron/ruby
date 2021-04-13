class QuestionnaireAlgorithm < ApplicationRecord
	belongs_to :user
	belongs_to :questionnaire_question
	belongs_to :algorithm_type
end
