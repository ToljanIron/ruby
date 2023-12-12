class GroupPolicy < ApplicationPolicy

  def index?
    if user.admin? || user.super_admin? || user.manager? || user.editor?
      return true
    end
    return false
  end

  def viewer?
    return false if questionnaire.nil?
    return true if (user.super_admin? || user.admin?)
    qids = user.questionnaire_permissions.pluck(:questionnaire_id)
    if qids.include? questionnaire.id
      return true
    end
    return false
  end
end
