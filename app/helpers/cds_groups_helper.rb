module CdsGroupsHelper
  def convert_formal_structure_to_group_id_child_groups_pairs(group_id)
    cache_key = "formal-to-child-group-paires-#{group_id}"
    res = cache_read(cache_key)
    unless res
      group = Group.where(id: group_id)[0]
      descendants_ids = Group.where(parent_group_id: group.id).pluck(:id)
      if descendants_ids.length > 0
        child_groups = []
        descendants_ids.each do |id|
          child_groups.push convert_formal_structure_to_group_id_child_groups_pairs id
        end
        res = { group_id: group_id, child_groups: child_groups }
      else
        res = { group_id: group_id, child_groups: [] }
      end
      cache_write(cache_key, res)
    end
    res
  end

  def self.get_subgroup_ids_only_1_level_deep(gid)
    group_ids = []
    convert_formal_structure_to_group_id_child_groups_pairs(gid)[:child_groups].each do |group_hash|
      group_ids.push(group_hash[:group_id])
    end
    return group_ids
  end

  def self.get_subgroup_ids_only_1_level_deep_with_at_least_5_emps(gid)
    group_ids = []
    convert_formal_structure_to_group_id_child_groups_pairs(gid)[:child_groups].each do |group_hash|
      group_ids.push(group_hash[:group_id]) if Group.find(group_hash[:group_id]).extract_employees.count > 5
    end
    return group_ids
  end

  def self.get_subgroup_ids_with_least_n_emps(gid, min_emps)
    cid = Group.find(gid).company_id
    groups = Group.where(company_id: cid)
    return groups.select { |g| g.extract_employees.count > min_emps }
  end

  def self.get_unit_size(cid, pid, gid, sid=nil)
    if (pid == -1) && (gid == -1)
      unit_size = Employee.by_company(cid, sid).count
    elsif (pid == -1) && (gid != -1)
      grp = Group.find(gid)
      unit_size = grp.extract_employees.length
    elsif (pid != -1) && (gid == -1)
      unit_size = EmployeesPin.size(pid)
    end
    return unit_size
  end

  def self.get_inner_select_by_group(gid)
    group = Group.find(gid)
    empsarr = group.extract_employees
    return empsarr.join(',')
  end

  def self.get_inner_select_by_group_as_arr(gid)
    id = (gid.class == Fixnum) ? gid : gid.id
    group = Group.find(id)
    group.extract_employees
  end

  def self.group_level(g)
    return nil unless g
    level = 0
    while g.parent_group_id
      g = Group.find(g.parent_group_id)
      level += 1
    end
    return level
  end
end
