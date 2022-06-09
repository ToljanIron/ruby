class GroupPolicy < ApplicationPolicy

  def index?
    if user.admin? || user.super_admin? || user.manager? || user.editor?
      return true
    end
    return false
  end

end
