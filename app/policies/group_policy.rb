class GroupPolicy < ApplicationPolicy

  def index?
    if user.admin? || user.hr? || user.manager?
      return true
    end
    return false
  end

  # Return max group this user is allowed to view, according
  # to the requested gid, and his permissions
  def self.get_max_allowed_group_id_for_user(gid, user_gid)
    
    res = gid
    if(gid == -1)
      # client asked group_id 0 or -1 -  meaning that client wants all groups. But, 
      # this is a manager and he is not allowed to view all groups. So take the 
      # max group id he is allowed to view, which is his group id (group_id in users table)
      res =  user_gid
    elsif(gid != user_gid)
      sub_group_ids = Group.find(user_gid).extract_descendants_ids
      # Take the managers group id if this is a group NOT in his sub groups.
      # Manager is only allowed to see his group and sub groups
      res = user_gid if !sub_group_ids.include?(gid)
    end
    return res
  end

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return Group.find(user['group_id']).extract_descendants_as_active_record_relation if user.manager?
      return scope.all
    end
  end
end
