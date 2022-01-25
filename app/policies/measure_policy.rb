class MeasurePolicy < ApplicationPolicy

  def index?
    true if user.admin? || user.super_admin? || user.manager?
  end
end