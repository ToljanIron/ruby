class EmployeePolicy < ApplicationPolicy
  def index?
    true if user.admin? || user.hr? || user.manager?
  end

  def self.is_user_allowed_to_view_emp(emp_id, user_gid)
    return Group.find(user_gid).is_emp_in_subgroup(emp_id)
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return Group.find(user['group_id']).extract_employees_records if (!user.admin? && !user.hr?)
      return scope.all
    end
  end
end