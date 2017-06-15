class RolePolicy < ApplicationPolicy


  def index?
    true if user.admin? or user.hr?
  end

  def update?
    true if user.admin?
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.where(company_id: user.company_id) if user.admin? || user.hr?
    end
  end
end
