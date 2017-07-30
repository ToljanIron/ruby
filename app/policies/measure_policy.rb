class MeasurePolicy < ApplicationPolicy

  def index?
    true if user.admin? || user.hr? || user.manager?
  end
end