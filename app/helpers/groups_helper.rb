module GroupsHelper
  def covert_formal_structure_to_group_id_child_groups_pairs(group_id)
    group = Group.where(id: group_id)[0]
    descendants_ids = Group.where(parent_group_id: group.id).pluck(:id)
    if descendants_ids.length > 0
      child_groups = []
      descendants_ids.each do |id|
        child_groups.push covert_formal_structure_to_group_id_child_groups_pairs id
      end
      res = { group_id: group_id, child_groups: child_groups, selected: false }
    else
      res = { group_id: group_id, child_groups: [], selected: false }
    end
    res
  end

  def get_unit_size(company_id, pinid, group_id)
    if (pinid == -1) && (group_id == -1)
      unit_size = Employee.where('company_id =?', company_id).count
    elsif (pinid == -1) && (group_id != -1)
      grp = Group.find(group_id)
      unit_size = grp.extract_employees.length
    elsif (pinid != -1) && (group_id == -1)
      unit_size = EmployeesPin.size(pinid)
    end
    return unit_size
  end

  def get_inner_select_by_group(gid)
    group = Group.find(gid)
    empsarr = group.extract_employees
    return empsarr.join(',')
  end

  def get_inner_select_by_group_as_arr(gid)
    gid = gid.class == Fixnum ? gid : gid.id
    group = Group.find(gid)
    group.extract_employees
  end

  def group_level(g)
    return nil unless g
    level = 0
    while g.parent_group_id
      g = Group.find(g.parent_group_id)
      level += 1
    end
    return level
  end
end
