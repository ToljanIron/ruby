class PinPolicy < ApplicationPolicy
  def index?
    true if user.admin? or user.hr?
  end

  def update?
    true if user.admin? or user.hr?
  end

  def delete?
    true if user.admin? or user.hr?
  end

  def permitted_attributes
    if user.admin? || user.hr?
      [:company_id, :name, :id, :definition]
    end
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.where(company_id: user.company_id, active: true) if user.admin? || user.hr?
    end
  end
end
