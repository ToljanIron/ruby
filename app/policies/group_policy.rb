class GroupPolicy < ApplicationPolicy

  def index?
    if user.admin? || user.super_admin? || user.manager? || user.regular?
      return true
    end
    return false
  end

end
