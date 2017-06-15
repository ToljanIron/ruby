class NetworkSnapshotDataPolicy < ApplicationPolicy

  def index?
    true if user.admin?
  end

  def update?
    true if user.admin?
  end
end
