class GroupPolicy < ApplicationPolicy

  def index?
    if user.admin? || user.hr? || user.manager?
      return true
    end
    return false
  end

end
