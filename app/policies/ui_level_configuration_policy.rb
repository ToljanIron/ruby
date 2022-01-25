class UiLevelConfigurationPolicy < ApplicationPolicy
  def index?
    true if user.admin? || user.super_admin? || user.manager?
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.where(company_id: user.company_id) if user.admin? || user.super_admin?
    end
  end
end
