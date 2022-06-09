class PinPolicy < ApplicationPolicy
  def index?
    true if user.admin? or user.super_admin? or user.manager?
  end

  def update?
    true if user.admin? or user.super_admin?
  end

  def delete?
    true if user.admin? or user.super_admin?
  end

  def permitted_attributes
    if user.admin? || user.super_admin?
      [:company_id, :name, :id, :definition]
    end
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.where(company_id: user.company_id, active: true) if user.admin? || user.super_admin?
    end
  end
end
