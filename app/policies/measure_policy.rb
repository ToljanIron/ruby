class MeasurePolicy < ApplicationPolicy

  def index?
    true if user.admin? or user.hr?
  end

end
