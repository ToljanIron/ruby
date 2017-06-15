class EmployeePolicy < ApplicationPolicy
  def index?
    true if user.admin? || user.hr?
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.where('company_id = ? and email != ?', user.company_id, 'other@mail.com') if user.admin? || user.hr?
    end
  end
end
