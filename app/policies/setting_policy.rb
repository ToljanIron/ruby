class SettingPolicy < ApplicationPolicy
  def index?
    true if user.admin? || user.super_admin? || user.manager? || user.regular?
  end

  def update?
    true if user.admin? || user.super_admin? || user.regular?
  end

  def admin?
    true if user.admin? || user.super_admin?
  end
end
