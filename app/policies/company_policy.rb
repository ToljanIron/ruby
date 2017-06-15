class CompanyPolicy < ApplicationPolicy
  def index?
    true if user.admin?
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.where(company_id: user.company_id) if user.admin?
    end
  end
end
