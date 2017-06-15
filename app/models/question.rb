require 'csv'
class Question < ActiveRecord::Base
  belongs_to :company

  has_many :questionnaire_questions
  has_many :questionnaires, through: :questionnaire_questions
 end
