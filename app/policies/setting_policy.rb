class SettingPolicy < ApplicationPolicy
  def index?
    true if user.admin? || user.super_admin? || user.manager? || user.editor?
  end

  def update?
    true if user.admin? || user.super_admin? || user.editor?
  end

  def admin?
    true if user.admin? || user.super_admin?
  end
end
