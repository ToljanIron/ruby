class InteractPolicy < ApplicationPolicy

  def authorized?
    if user.admin? || user.super_admin? || user.manager? || user.regular?
      return true
    end
    return false
  end

  def view_reports?
    if user.admin? || user.super_admin? || user.manager? || user.regular?
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
    return user.super_admin? || (user.admin? && user.is_allowed_create_questionnaire)
  end

  def manage_users?
    if user.super_admin? || (user.admin? && user.is_allowed_add_users)
      return true
    end
    return false
  end

  def super_admin?
    return user.super_admin?
  end

end
