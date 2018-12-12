class InteractPolicy < ApplicationPolicy

  def authorized?
    if user.admin? || user.hr?
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
end
