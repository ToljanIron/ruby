require './app/helpers/employee_management_relation_helper.rb'
module FlagsHelper
  include PinsHelper
  include EmployeeManagementRelationHelper
  include SelectionHelper

  NO_PIN   ||= -1
  NO_GROUP ||= -1
  MEASURE  ||= 1
  ID  ||= 0

  IN  ||= 'employee_id'
  OUT ||= 'advicee_id'

  def get_likely_flag(_company_id, friendship_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    res_a = []
    res_f = []
    avg_a_in = get_a_in_avg(friendship_snapshot_id, pid, gid)
    a = format_from_activerecord_result(get_a_in(friendship_snapshot_id, pid, gid))
    f = get_f_in_n(friendship_snapshot_id, pid, gid)
    a.each do |candidate|
      res_a << { id: candidate[:id] } if candidate[:measure].to_f > avg_a_in
    end
    f.each do |candidate|
      res_f << { id: candidate[:id] } if candidate[:measure] == 0
    end
    intersection = res_a & res_f
    return intersection
  end

  def most_promising(company_id, friendship_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    max_size = 10
    advisors = format_from_activerecord_result(get_a_in(friendship_snapshot_id, pid, gid))
    advisors = advisors.each { |node| node[:measure] = node[:measure].to_i } ## hack to convert measure values to integers
    advisors = advisors.sort_by { |k| k[:measure] }.reverse   ## if a_in_n isn't sorted
    socials = get_most_social(friendship_snapshot_id, pid, gid)
    group_or_pin_size = get_unit_size(company_id, pid, gid)
    potential_candidates_size = group_or_pin_size > max_size ? max_size :  group_or_pin_size
    # return calc_promising()
    s = socials[0..potential_candidates_size - 1].map { |elem| elem.except(:measure) }  ## remove measure attribute from hashes
    a = advisors[0..potential_candidates_size - 1].map { |elem| elem.except(:measure) }
    intersected = s & a
    return intersected
    # possibly filter zeros?
  end

  def most_bypassed_manager(company_id, friendship_snapshot_id, pid = NO_PIN, gid = NO_GROUP)
    max_size = 5
    informal_matrix = create_informal_matrix_per_snapshot(friendship_snapshot_id, pid, gid)
    bypassed_managers = get_bypassed_in(informal_matrix, company_id, pid, gid)
    potential_candidates_size = bypassed_managers.length > max_size ? max_size : bypassed_managers.length
    if potential_candidates_size != 0
      res = bypassed_managers[0..potential_candidates_size - 1].map { |elem| elem.except(:measure) }
    else
      res = []
    end
    return res
  end

  # def team_glue(company_id, friendship_snapshot_id, pid = NO_PIN, gid = NO_GROUP)   DEAD CODE byebug asaf
  #   res = []
  #   graph = create_advice_as_graph(friendship_snapshot_id, company_id, pid, gid)
  #   return res unless graph_connected?(graph)
  #   if graph[:vertices].nil?
  #     puts graph
  #   end
  #   graph[:vertices].each do |emp_id|
  #     ans = false
  #     temp_graph = remove_employee_from_graph(graph, emp_id)
  #     dfs = DFS.new(temp_graph[:adjacency_list])
  #     vertices = graph[:vertices] - [emp_id]
  #     if vertices.nil?
  #       puts graph
  #     end
      
  #     vertices.each do |vertex|
  #       dfs.dfs_run!(vertex.to_s)
  #       ans = true if dfs.parent.keys.size != vertices.size
  #       dfs.parent = {}
  #     end
      
  #     if graph[:vertices].nil?
  #       puts graph
  #     end
  #     res << { id: emp_id } if ans == true
  #   end

  #   res
  # end
end
