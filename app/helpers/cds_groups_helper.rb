module CdsGroupsHelper
  def self.convert_formal_structure_to_group_id_child_groups_pairs(group_id)
    cache_key = "formal-to-child-group-paires-#{group_id}"
    res = cache_read(cache_key)
    unless res
      group = Group.where(id: group_id)[0]
      descendants_ids = Group.where(parent_group_id: group.id).pluck(:id)
      if descendants_ids.length > 0
        child_groups = []
        descendants_ids.each do |id|
          child_groups.push CdsGroupsHelper.convert_formal_structure_to_group_id_child_groups_pairs id
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
    CdsGroupsHelper.convert_formal_structure_to_group_id_child_groups_pairs(gid)[:child_groups].each do |group_hash|
      group_ids.push(group_hash[:group_id])
    end
    return group_ids
  end

  def self.get_subgroup_ids_only_1_level_deep_with_at_least_5_emps(gid)
    group_ids = []
    CdsGroupsHelper.convert_formal_structure_to_group_id_child_groups_pairs(gid)[:child_groups].each do |group_hash|
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
    id = (gid.class == Integer) ? gid : gid.id
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

  def self.groups_with_sizes(gids)
    sqlstr = "
      SELECT g.id AS group_id, g.name AS group_name, g.parent_group_id AS parent_id,
        (SELECT count(*)
         FROM employees AS emps
         WHERE emps.group_id = g.id) AS num_of_emps
      FROM groups AS g
      WHERE g.id in (#{gids.join(',')})"
    res = ActiveRecord::Base.connection.select_all(sqlstr)
    ret = format_names_and_child_groups(res)
    return ret
  end

  def is_root_group?(group, groups_inx)
    pgid = group[:parentId]
    return pgid.nil? || groups_inx[pgid].nil?
  end

  ## 1st pass - Create all linear time properties and create an index
  ## 2nd pass - Use index to get children list
  ## 3rd pass - Use index to calculate group's depth
  ## 4th pass - Use index to calculate group's accumulated size
  def self.format_names_and_child_groups(groups_list)
    is_investigation_mode = CompanyConfigurationTable::is_investigation_mode?
    groups_inx = {}
    root_gid = nil
    groups_list.each do |g|
      group = {}
      gid = g['group_id']
      pgid = g['parent_id']
      group[:gid] = gid
      group[:id] = gid
      root_gid = gid if pgid.nil?
      group[:name] = !is_investigation_mode ? g['group_name'] : "#{g['group_id']}_#{g['group_name']}"
      group[:parentId] = pgid
      group[:size] = g['num_of_emps']
      group[:childrenIds] = []
      group[:accumulatedSize] = -1
      groups_inx[gid] = group
    end

    ## Force root group parent_id to be nil in case it is not (Interact
    groups_inx.each do |k, g|
      gid = g[:id]
      next if !is_root_group?(g, groups_inx)
      root_gid = gid
      g[:parentId] = -1
    end

    ## find children ids
    groups_inx.each do |k, g|
      pgid = g[:parentId]
      next if pgid.nil? || pgid == -1
      groups_inx[pgid][:childrenIds] << g[:gid]
    end

    ## calculate depth
    group_depth(groups_inx, root_gid, 0)

    ## Recursively calculate groups accoumulated sizes
    group_accoumulated_size(groups_inx, root_gid)

    return groups_inx
  end

  def self.group_depth(groups_inx, gid, depth)
    groups_inx[gid][:depth] = depth
    child_ids = groups_inx[gid][:childrenIds]
    child_ids.each do |cgid|
      group_depth(groups_inx, cgid, depth + 1)
    end
  end

  def self.group_accoumulated_size(groups_inx, gid)
    group = groups_inx[gid]
    accsize = group[:size]
    group[:childrenIds].each do |cgid|
      child_group = groups_inx[cgid]
      if (child_group[:accumulatedSize] > -1)
        accsize += child_group[:accumulatedSize]
      elsif (child_group[:childrenIds].length == 0)
        accsize += child_group[:size]
        child_group[:accumulatedSize] = child_group[:size]
      else
        accsize += group_accoumulated_size(groups_inx, cgid)
      end
    end
    group[:accumulatedSize] = accsize == -1 ? group[:size] : accsize
    return accsize
  end
end
