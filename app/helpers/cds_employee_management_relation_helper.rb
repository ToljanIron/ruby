module CdsEmployeeManagementRelationHelper
  NO_PIN   = -1
  NO_GROUP = -1

  ID      = 0
  MEASURE = 1

  IN  = 'manager_id'
  OUT = 'employee_id'

  def self.create_relation_matrix(company_id, pid = NO_PIN, gid  = NO_GROUP)
    res = []
    inner_select = CdsSelectionHelper.get_inner_select_as_arr(company_id, pid, gid)
    all_relations = EmployeeManagementRelation.where(relation_type: 0, employee_id: inner_select, manager_id: inner_select).select(:manager_id, :employee_id)
    all_relations.each do |active_manager|
      res << { from: active_manager.employee_id, to: active_manager.manager_id, value: 1 }
    end
    # add null relations
    all_possible_relations = inner_select.permutation(2).to_a
    count = 0
    # find if exist in already, else push them with value 0
    all_possible_relations.each do |rel_arr|
      possible_existing_relation = { from: rel_arr[0], to: rel_arr[1], value: 1 }
      unless res.include? possible_existing_relation
        count += 1
        res << { from: rel_arr[0], to: rel_arr[1], value: 0 }
      end
    end

    res = res.sort { |a, b| [a[:from], a[:to]] <=> [b[:from], b[:to]] }
    return res
  end

  def self.create_informal_matrix_per_snapshot(snapshot_id, network_id, pid = NO_PIN, gid = NO_GROUP)
    company_id = find_company_by_snapshot(snapshot_id)
    employee_management_relations = create_relation_matrix(company_id, pid, gid)
    advise_relations = AlgorithmsHelper.create_advise_matrix_per_snapshot(snapshot_id, network_id, pid, gid)
    minimum = [employee_management_relations.length, advise_relations.length].min
    (0..(minimum) - 1).each do |index|
      advise_relations[index][:value] = 10 * advise_relations[index][:value]
      advise_relations[index][:value] = advise_relations[index][:value] + employee_management_relations[index][:value]
    end
    return advise_relations
  end

  def self.get_bypassed_in(informal_matrix, company_id, pid = NO_PIN, gid = NO_GROUP)
    value_of_non_advised_but_subordinate = 1
    filtered_for_subordinate_non_advised = informal_matrix.map { |x| x if x[:value] == value_of_non_advised_but_subordinate }.compact
    informal_in = reduce_informal_subordinate_non_advised_by_to(filtered_for_subordinate_non_advised)
    unit_employees = Employee.where(company_id: company_id).pluck(:id)
    managers_count = EmployeeManagementRelation.where(relation_type: 0).pluck(:manager_id).select { |m| unit_employees.include? m }.uniq.length
    return [] if managers_count < 5
    r_in = get_r_in(company_id, pid, gid)
    res = []
    # check only for managers: look for their corresponding informal entry and divide it by the corresponding value in r_in
    r_in.map do |candidate|
      to_push = informal_in.select { |entry| entry[:id] == candidate[:id] }
      unless to_push.empty?
        to_push.first[:measure] = to_push.first[:measure] / candidate[:measure].to_f
        res.push(to_push.first)
      end
    end
    return res
  end

  def self.reduce_informal_subordinate_non_advised_by_to(informal_matrix)
    res = []
    memoized_tos = []
    informal_matrix.each do |x|
      next if memoized_tos.include? x[:to]
      memoized_tos.push x[:to]
      c = informal_matrix.select { |y| y[:to] == x[:to] }.count
      temp_hash_res = {}
      temp_hash_res[:id] = x[:to]
      temp_hash_res[:measure] = c
      res.push(temp_hash_res)
    end
    res = res.sort_by { |k| k[:measure] }.reverse
    return res
  end

  def self.combine_r_and_a_matrices(advise_rel, employee_management_relations)
    (0..(advise_rel.length) - 1).each do |index|
      advise_rel[index][:value] = 10 *  advise_rel[index][:value]
      advise_rel[index][:value] = advise_rel[index][:value] + employee_management_relations[index][:value]
    end
    return advise_rel
  end

  def self.get_r_in(company_id, pid = NO_PIN, gid = NO_GROUP)
    res = get_r(company_id, IN, pid, gid)
    return CdsSelectionHelper.format_from_activerecord_result(res)
  end

  module_function

  def get_r(company_id, groupby, pid = NO_PIN, gid = NO_GROUP)
    inner_select = get_inner_select_for_employee_management(company_id, pid, gid)
    employees = ActiveRecord::Base.connection.select_all('select employee_id from employee_management_relations').rows.join(',')
    query = "select #{groupby}, count(employee_id)  from employee_management_relations where relation_type = 0"
    query += " and employee_id in (#{inner_select} ) " \
    " and manager_id in (#{inner_select}) and manager_id in (#{employees}) "
    query += " group by #{groupby} order by count(employee_id) desc"
    return ActiveRecord::Base.connection.select_all(query)
  end

  def get_inner_select_for_employee_management(company_id, pinid, gid)
    return CdsGroupsHelper.get_inner_select_by_group(gid) if pinid == NO_PIN && gid != NO_GROUP
    return CdsPinsHelper.get_inner_select_by_pin(pinid) if pinid != NO_PIN && gid == NO_GROUP
    fail 'Ambiguous sub-group request with both pin-id and group-id' if pinid != NO_PIN && gid != NO_GROUP
    return "select id from employees where company_id = #{company_id}"
  end

  # def get_relations_arr(_pid, _gid, snapshot) DEAD CODE ASAF BYEBUG
  #   return "select employee_id, friend_id from friendships_snapshots where friend_flag = 1
  #   AND snapshot_id = #{snapshot} "
  # end

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
