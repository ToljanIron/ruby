class QuestionnairePolicy < ApplicationPolicy

  attr_reader :user, :questionnaire

  def initialize(user, questionnaire)
    @user = user
    @questionnaire = questionnaire
  end
  
  def index?
    qids = user.questionnaire_permissions.pluck(:questionnaire_id)
    if qids.include? questionnaire.id
      return true
    end
    return false
  end

  def admin?
    questionnaires = user.questionnaire_permissions.where(questionnaire_id: questionnaire.id)
    level = questionnaires.first.level if questionnaires.length > 0
    return level == 'admin'
  end

  def viewer?
    qids = user.questionnaire_permissions.pluck(:questionnaire_id)
    if qids.include? questionnaire.id
      return true
    end
    return false
  end
  
end
  