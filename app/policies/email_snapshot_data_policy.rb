class EmailSnapshotDataPolicy < ApplicationPolicy

  def index?
    true if user.admin? or user.super_admin?
  end

  def permitted_attributes
    if user.admin? || user.super_admin?
      [:others, :degree_type, :time_fitler, :others_status, :cid, :pid, :gid, :measure_type]
    end
  end
end
