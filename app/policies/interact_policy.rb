class InteractPolicy < ApplicationPolicy

  def authorized?
    if user.admin? || user.hr? || user.manager?
      return true
    end
    return false
  end

  def view_reports?
    if user.admin? || user.hr? || user.manager?
      return true
    end
    return false
  end

  def admin_only?
    if user.admin?
      return true
    end
    return false
  end

  def create_questionnaire?
    return user.is_allowed_create_questionnaire
  end

end
