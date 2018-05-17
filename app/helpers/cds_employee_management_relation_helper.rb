module CdsEmployeeManagementRelationHelper
  NO_PIN   ||= -1
  NO_GROUP ||= -1

  module_function

  ####################################
  # Return eids of all managers
  ####################################
  def get_all_managers(sid, gid)
    managers =
      EmployeeManagementRelation
        .select("emr.manager_id")
        .from("employee_management_relations AS emr")
        .joins("JOIN employees AS emps ON emps.id = emr.manager_id")
        .where("emps.snapshot_id = %s and emps.group_id = %s", sid, gid)
        .distinct
    return managers.map { |emr| emr.manager_id }
  end

  ####################################
  # Return all peers of eid
  ####################################
  def get_peers(eid)
    manager = EmployeeManagementRelation.where(employee_id: eid).last
    return nil if manager.nil?
    peers =
      EmployeeManagementRelation
        .where(manager_id: manager.id)
        .where.not(employee_id: eid)
        .pluck(:employee_id)
    return nil if peers.empty?
    return peers
  end

  ####################################
  # Return top manager of company
  ####################################
  def get_top_manager(eid=nil, depth=0)
    eid = Employee.first.id if eid == nil
    mid = EmployeeManagementRelation.where(employee_id: eid).last.try(:manager_id)
    return eid if mid == nil
    newdepth = depth + 1
    raise "Recursive search went too deep, eid: #{eid}, mid: #{mid}" if newdepth == 20
    return get_top_manager(mid, depth + 1)
  end

  ####################################
  # Return a quick access structure of the following type:
  # {
  #   topeid: <manager id>,
  #   peers: { eid: array of peers, .... },
  #   managers: { eid: manager id, ... },
  #   reportees: { eid: array of emps, ...}
  # }
  ####################################
  def formal_structure_index(sid)
    rels =
      EmployeeManagementRelation
        .select("emr.manager_id, emr.employee_id")
        .from("employee_management_relations AS emr")
        .joins("JOIN employees AS emps ON emps.id = emr.manager_id")
        .where("emps.snapshot_id = %s", sid)

    ret = {
      topid: get_top_manager(),
      peers: {},
      managers: {},
      reportees:{}
    }

    ## First pass to identify managers and reportees
    rels.each do |rel|
      mid = rel.manager_id
      eid = rel.employee_id
      ret[:managers][eid] = mid
      ret[:reportees][mid] << eid  if !ret[:reportees][mid].nil?
      ret[:reportees][mid] = [eid] if ret[:reportees][mid].nil?
      ret[:peers][mid] = [] if ret[:peers][mid].nil?
    end

    ## Second pass for manager the peers
    managers = ret[:managers].values.uniq
    managers.each do |mid,v|
      next if ret[:reportees][mid].nil?
      mmid = ret[:managers][mid]
      next if mmid.nil?
      peer_candidates = ret[:reportees][mmid]
      peer_candidates.each do |pc|
        next if pc == mid
        next if ret[:reportees][pc].nil?
        ret[:peers][mid] << pc
      end
    end

    return ret
  end

  def get_all_emps(cid, pid, gid)
    if pid == NO_PIN && gid != NO_GROUP
      group = Group.find(gid)
      empsarr = group.extract_employees
      return empsarr
    end
    if pid != NO_PIN && gid == NO_GROUP
      return EmployeesPin.where(pin_id: pid).pluck(:employee_id)
    end
    if pid != NO_PIN && gid != NO_GROUP
      fail 'Ambiguous sub-group request with both pin-id and group-id'
    end
    return Employee.where(company_id: cid).pluck(:id)
  end
end
