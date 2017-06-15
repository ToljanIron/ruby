require './app/helpers/dfs_helper.rb'
module AdviseHelper
  include PinsHelper
  include GroupsHelper
  include SelectionHelper
  include DfsHelper

  NO_PIN   ||= -1
  NO_GROUP ||= -1
  MEASURE  ||= 1
  ID       ||= 0

  OUT  ||= 'employee_id'
  IN   ||= 'advicee_id'
  BOSS ||= 10
  ADVICEE_BOSS ||= 11

  # def create_advice_as_graph(snapshot_id, cid, pid, gid)  DEAD CODE asaf byebug
  #   res = {}
  #   emp_from_list = []
  #   inner_select = get_inner_select(pid, gid)
  #   query = "select advicee_id, employee_id, advice_flag from advices_snapshots where snapshot_id = #{snapshot_id} and advice_flag = 1 "
  #   unless inner_select.nil?
  #     query += "and employee_id in (#{inner_select} ) " \
  #     "and advicee_id   in (#{inner_select}) "
  #   end
  #   partial_active_result = ActiveRecord::Base.connection.select_all(query)
  #   partial_active_result.rows.each do |row|
  #     if !emp_from_list.include?(row[0].to_i)
  #       res[row[0]] = []
  #       emp_from_list  << row[0].to_i
  #       res[row[0]] << row[1]
  #     else
  #       res[row[0]] << row[1]
  #     end
  #   end
  #   all_emps = get_all_emps_advice(cid, pid, gid)
  #   remaining_emps = all_emps - emp_from_list
  #   remaining_emps.each do |emp_id|
  #     res[emp_id.to_s] = []
  #   end
  #   return{ vertices: all_emps, adjacency_list: res }
  # end

  def remove_employee_from_graph(graph, emp_id)
    graph_temp = graph.deep_dup # deep copy of graph
    vertices = graph_temp[:vertices]
    edges = graph_temp[:adjacency_list]
    vertices -= [emp_id]
    edges.each do |key, value|
      edges[key] = value - [emp_id.to_s]
    end
    edges.each do |key, _value|
      edges[key] = [] if key.to_s.eql?(emp_id.to_s)
    end
    { vertices: vertices, adjacency_list: edges }
  end

  def graph_connected?(graph)
    ans = true
    dfs = DFS.new(graph[:adjacency_list])
    vertices = graph[:vertices]
    vertices.each do |vertex|
      dfs.dfs_run!(vertex.to_s)
      ans = false if dfs.parent.keys.size != vertices.size
      dfs.parent = {}
    end
    return ans
  end

  def create_advise_matrix_per_snapshot(snapshot_id, pid = NO_PIN, gid  = NO_GROUP)
    res = []
    company_id = find_company_by_snapshot(snapshot_id)
    inner_select = get_inner_select_as_arr(company_id, pid, gid)   # array
    all_relations = AdvicesSnapshot.where(snapshot_id: snapshot_id, advice_flag: 1, employee_id: inner_select, advicee_id: inner_select).select(:advicee_id, :employee_id, :advice_flag)
    all_relations.each do |active_advise|
      res << { from: active_advise.advicee_id, to: active_advise.employee_id, value: 1 }
    end
    res = remove_duplicate_advice(res)
    # add null relations
    all_possible_relations = inner_select.permutation(2).to_a
    # find if exist in already, else push them with value 0
    all_possible_relations.each do |rel_arr|
      possible_existing_relation = { from: rel_arr[0], to: rel_arr[1], value: 1 }
      res << { from: rel_arr[0], to: rel_arr[1], value: 0 } unless res.include? possible_existing_relation
    end
    res = res.sort { |a, b| [a[:from], a[:to]] <=> [b[:from], b[:to]] }
    return res
  end

  # def get_advice_relations_arr(_pid, _gid, snapshot)    DEAD CODE byebug asaf
  #   return "select employee_id, advicee_id from advices_snapshots where advice_flag = 1
  #   AND snapshot_id = #{snapshot} "
  # end
  # 
  # def calculate_pair_advice_per_snapshot(snapshot_id, pid = NO_PIN, gid  = NO_GROUP)
  #   inner_select = get_inner_select(pid, gid)
  #   snapshot = Snapshot.where(id: snapshot_id).last
  #   recent_snapshot = snapshot.id
  #   dt = snapshot.timestamp.to_i
  #   query = get_advice_relations_arr(pid, gid, recent_snapshot)
  #   unless inner_select.nil?
  #     query += "and employee_id in (#{inner_select} ) " \
  #     "and advicee_id in (#{inner_select}) "
  #   end
  #   temp_res = ActiveRecord::Base.connection.select_all(query)
  #   return format_to_analyze(temp_res, dt)
  # end

  def get_a_in(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    return get_a(snapshot_id, IN, pid, gid)
  end

  def get_a_out(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    return get_a(snapshot_id, OUT, pid, gid)
  end

  def get_a_in_avg(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    sum = 0
    res = get_a_in(snapshot_id, pid, gid)
    res.rows.each do |row|
      sum += row[MEASURE].to_i
    end
    company_id = find_company_by_snapshot(snapshot_id)
    unit_size = get_unit_size(company_id, pid, gid)
    fail 'No Employees found!' if unit_size == 0
    return (sum.to_f / unit_size.to_f).round(2)
  end

  def get_a_in_n(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    a_in = get_a_in(snapshot_id, pid, gid)
    company_id = find_company_by_snapshot(snapshot_id)
    unit_size = get_unit_size(company_id, pid, gid)
    fail 'No Employees found!' if unit_size == 0
    a_in_n = a_in
    a_in_n.rows.each do |row|
      val = row[MEASURE].to_f / unit_size
      row[MEASURE] = val.round(2)
    end
    res = format_from_activerecord_result(a_in_n)
    return res
  end

  def get_a_out_n(snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    a_out = get_a_out(snapshot_id, pid, gid)
    company_id = find_company_by_snapshot(snapshot_id)
    unit_size = get_unit_size(company_id, pid, gid)
    fail 'No Employees found!' if unit_size == 0
    a_out_n = a_out
    a_out_n.rows.each do |row|
      val = row[MEASURE].to_f / unit_size
      row[MEASURE] = val.round(2)
    end
    res = format_from_activerecord_result(a_out_n)
    return res
  end

  def find_most_expert(snapshotid, pinid, gid)
    get_a_in_n(snapshotid, pinid, gid).sort_by { |k| k[:measure] }.reverse
  end

  def find_company_by_snapshot(snapshot_id)
    Snapshot.where(id: snapshot_id).first.company_id
  end

  private

  def get_all_emps_advice(cid, pid, gid)
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

  def format_to_analyze(ar, dt)
    ret = []
    ar.rows.each do |row|
      ret << { from_emp_id: row[ID].to_i, to_emp_id: row[MEASURE].to_i, weight: 1, dt: dt * 1000 }
    end
    return ret
  end

  # def get_a(snapshot_id, groupby, pid = NO_PIN, gid = NO_GROUP)   DEAD CODE byebug asaf
  #   inner_select = get_inner_select(pid, gid)
  #   # recent_snapshot_id = AdvicesSnapshot.order(snapshot_id: :asc).last.snapshot_id
  #   query = "SELECT #{groupby}, sum(advice_flag)  from advices_snapshots " + "where snapshot_id = #{snapshot_id} "
  #   unless inner_select.blank?
  #     query += "and employee_id in (#{inner_select} ) " \
  #              "and advicee_id   in (#{inner_select}) "
  #   end
  #   query += " group by #{groupby} order by sum(advice_flag) asc"
  #   return ActiveRecord::Base.connection.select_all(query)
  # end

  def remove_duplicate_advice(advice_matrix)
    advice_matrix.uniq
  end

  def get_inner_select(pinid, gid)
    return get_inner_select_by_group(gid) if pinid == NO_PIN && gid != NO_GROUP
    return get_inner_select_by_pin(pinid) if pinid != NO_PIN && gid == NO_GROUP
    fail 'Ambiguous sub-group request with both pin-id and group-id' if pinid != NO_PIN && gid != NO_GROUP
    return nil
  end
end
