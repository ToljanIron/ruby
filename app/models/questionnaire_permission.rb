class QuestionnairePermission < ApplicationRecord
    belongs_to :company
    belongs_to :questionnaire
    belongs_to :user
    enum level: [:admin, :viewer]
end
