class SettingPolicy < ApplicationPolicy
  def index?
    true if user.admin? || user.hr?
  end
end
