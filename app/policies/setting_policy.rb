class SettingPolicy < ApplicationPolicy
  def index?
    true if user.admin? || user.hr? || user.manager?
  end

  def admin?
    true if user.admin? || user.hr?
  end
end
