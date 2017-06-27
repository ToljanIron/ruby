class GroupPolicy < ApplicationPolicy

  def index?
    true if user.admin? or user.hr?
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return nil
    end
  end
end
