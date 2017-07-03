module ParamsToArgsHelper
  extend AlgorithmsHelper
  extend CdsEmployeeManagementRelationHelper

  MEASURE = 1
  FLAG    = 2
  ANALYZE = 3
  GROUP   = 4

  ########################## v3 algorithms ##############################
  ########################## Email ##########################
  def self.spammers_measure(args)
    key = "spammers_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.spammers_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.blitzed_measure(args)
    key = "blitzed_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.blitzed_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.relays_measure(args)
    key = "relays_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.relays_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end
  def self.ccers_measure(args)
    key = "ccers_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.ccers_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.cced_measure(args)
    key = "cced_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.cced_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.undercover_measure(args)
    key = "undercover_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.undercover_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.politicos_measure(args)
    key = "politicos_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.politicos_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.emails_volume_measure(args)
    key = "emails_volume_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.emails_volume_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.deadends_measure(args)
    key = "deadends_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.deadends_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  ########################## Meetings ##########################
  
  def self.in_the_loop_measure(args)
    key = "in_the_loop_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.in_the_loop_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.rejecters_measure(args)
    key = "rejecters_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.rejecters_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.routiners_measure(args)
    key = "routiners_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.routiners_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.inviters_measure(args)
    key = "inviters_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.inviters_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.observers_measure(args)
    key = "observers_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    puts "params to args: #{args[:gid]}"
    return CdsUtilHelper.read_or_calculate_and_write(key) do
      return AlgorithmsHelper.observers_measure(args[:snapshot_id], args[:gid], args[:pid])
    end
  end

  def self.num_of_ppl_in_meetings_gauge(args)
    return AlgorithmsHelper.avg_num_of_ppl_in_meetings(args[:snapshot_id], args[:gid], args[:pid])
  end

  def self.avg_time_spent_in_meetings_gauge(args)
    return AlgorithmsHelper.avg_time_spent_in_meetings_per_group(args[:snapshot_id], args[:gid], args[:pid])
  end

  ########################## v2 and V1 algorithms #######################

  def self.most_isolated_to_args(args)
    res = get_friends_relation_in_network(args[:snapshot_id], args[:network_id], args[:pid], args[:gid])
    return ParamsToArgsHelper.calculate_per_snapshot_and_pin(res, args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.no_of_emails_sent(args)
    return AlgorithmsHelper.no_of_emails_sent(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.no_of_emails_sent_for_explore(args)
    return AlgorithmsHelper.no_of_emails_sent_for_explore(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.no_of_emails_received(args)
    return AlgorithmsHelper.no_of_emails_received(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.no_of_emails_received_for_explore(args)
    return AlgorithmsHelper.no_of_emails_received_for_explore(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.average_no_of_attendees_gauge(args)
    return AlgorithmsHelper.average_no_of_attendees(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.proportion_time_spent_on_meetings_gauge(args)
    return AlgorithmsHelper.proportion_time_spent_on_meetings(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.proportion_of_managers_never_in_meetings_gauge(args)
    return AlgorithmsHelper.proportion_of_managers_never_in_meetings(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.calculate_representatives(args)
    return AlgorithmsHelper.calculate_representatives(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.find_most_expert_to_args(args)
    data = find_most_expert_worker(args[:snapshot_id], args[:pid], args[:gid], args[:network_id])
    if args[:algorithm_type] == MEASURE
      return ParamsToArgsHelper.calculate_per_snapshot_and_pin(data, args[:snapshot_id], args[:pid], args[:gid])
    elsif args[:algorithm_type] == ANALYZE
      return ParamsToArgsHelper.questionnaire_based_analyze_for_precalculation(data, args[:company_id], args[:pid], args[:gid])
    end
  end

  def self.at_risk_of_leaving_to_args(args)
    res = get_likely_to_leave_flag(args[:network_b_id], args[:network_id], args[:snapshot_id], args[:pid], args[:gid])
    return ParamsToArgsHelper.calculate_flags(res)
  end

  def self.most_bypassed_manager_to_args(args)
    res = most_bypassed_managers(args[:company_id], args[:snapshot_id], args[:network_id], args[:pid], args[:gid])
    return ParamsToArgsHelper.calculate_flags(res)
  end

  def self.in_the_loop_to_args(args)
    res = in_the_loop_algorithm(args[:snapshot_id], args[:gid], args[:pid])
    ParamsToArgsHelper.calculate_per_snapshot_and_pin(res, args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.politician_to_args(args)
    res = politician_algorithm(args[:snapshot_id], args[:gid], args[:pid])
    ParamsToArgsHelper.calculate_per_snapshot_and_pin(res, args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.proportion_of_emails(args)
    return AlgorithmsHelper.proportion_of_emails(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.calculate_gate_keepers(args)
    res = ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    return AlgorithmsHelper.calculate_gate_keepers(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.avg_subject_length(args)
    return AlgorithmsHelper.avg_subject_length(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.avg_subject_length_to_explore(args)
    return AlgorithmsHelper.new_explore_for_gauge(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.calculate_bottlenecks(args)
    return AlgorithmsHelper.calculate_bottlenecks(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.volume_of_emails(args)
    data = AlgorithmsHelper.volume_of_emails(args[:snapshot_id], args[:pid], args[:gid])
    data.each do |grp|
      return [grp] if grp[:group_id].to_i == args[:gid].to_i
    end
    return [{group_id: args[:gid].to_i, measure: 0}]
  end

  def self.no_of_isolates(args)
    return AlgorithmsHelper.no_of_isolates(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.no_of_isolates_for_explore(args)
    return AlgorithmsHelper.no_of_isolates_for_explore(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.volume_of_emails_for_explore(args)
    return AlgorithmsHelper.volume_of_emails_for_explore(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.total_activity_centrality_to_args(args)
    res = total_activity_centrality_algorithm(args[:snapshot_id], args[:gid], args[:pid])
    ParamsToArgsHelper.calculate_per_snapshot_and_pin(res, args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.collaboration(args)
    if args[:algorithm_type] == MEASURE
      return ParamsToArgsHelper.measure_collaboration(args)
    else
      return ParamsToArgsHelper.analyze_collaboration(args)
    end
  end

  def self.analyze_collaboration(args)
    key = "get_snapshot_node_list_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    res = CdsUtilHelper.read_or_calculate_and_write(key) do
      emps_in_pin = CdsAdviseMeasureHelper.get_snapshot_node_list(args[:snapshot_id], false, args[:pid], args[:gid])
      CdsAdviseMeasureHelper.create_measure_list(emps_in_pin, true, args[:pid], args[:gid], args[:company_id])
    end
    if res
      res.map { |row| { id: row[:id], measure: row[:rate] / 10 } }
    else
      res = []
    end
  end

  def self.measure_collaboration(args)
    key = "get_snapshot_node_list_#{args[:snapshot_id]}_false_#{args[:pid]}_#{args[:gid]}"
    data = CdsUtilHelper.read_or_calculate_and_write(key) do
      emps_in_pin = CdsAdviseMeasureHelper.get_snapshot_node_list(args[:snapshot_id], false, args[:pid], args[:gid])
      emps_in_pin.rows.empty? ? [] : CdsAdviseMeasureHelper.create_measure_list(emps_in_pin, true, args[:pid], args[:gid], args[:company_id])
    end
    data = ParamsToArgsHelper.calculate_per_snapshot_and_pin(data, args[:snapshot_id], args[:pid], args[:gid])
    return data
  end

  def self.calculate_information_isolate_to_args(args)
    return args[:memorize] if !args[:memorize].nil?
    return AlgorithmsHelper.calculate_information_isolate(args[:snapshot_id], args[:network_id], args[:pid], args[:gid])
  end

  def self.political_power_flag(args)
    return AlgorithmsHelper.political_power_flag(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.political_power_flag_hidden_gauge(args)
    res = AlgorithmsHelper.political_power_flag_hidden_gauge(args[:snapshot_id], args[:pid], args[:gid])
    return res
  end

  def self.calculate_bottlenecks_for_flag(args)
    return AlgorithmsHelper.calculate_bottlenecks_for_flag(args[:snapshot_id], args[:pid], args[:gid])
  end

  def self.calculate_non_reciprocity_between_employees_to_args(args)
    return AlgorithmsHelper.calculate_non_reciprocity_between_employees(args[:snapshot_id], args[:network_id], args[:network_b_id], args[:pid].to_i, args[:gid].to_i)
  end

  def self.calculate_powerful_non_managers_hidden_gauge(args)
    if args[:memorize].nil?
      return AlgorithmsHelper.calculate_powerful_non_managers_hidden_gauge(args[:snapshot_id], args[:network_id], args[:network_b_id], args[:network_c_id], args[:pid].to_i, args[:gid].to_i)
    else
      return args[:memorize]
    end
  end

  def self.calculate_powerful_non_managers_to_args(args)
    if args[:memorize].nil?
      return AlgorithmsHelper.calculate_powerful_non_managers(args[:snapshot_id], args[:network_id], args[:network_b_id], args[:network_c_id], args[:pid].to_i, args[:gid].to_i)
    else
      return args[:memorize]
    end
  end

  def self.political_power_flag_explore(args)
    data = AlgorithmsHelper.political_power_flag(args[:snapshot_id], args[:pid].to_i, args[:gid].to_i)
    return ParamsToArgsHelper.email_based_analyze_for_precalculation(data, args[:company_id].to_i, args[:pid].to_i, args[:gid].to_i)
  end

  def self.calculate_information_isolate_explore_to_args(args)
    data = AlgorithmsHelper.calculate_information_isolate(args[:snapshot_id], args[:network_id], args[:pid].to_i, args[:gid].to_i)
    return ParamsToArgsHelper.email_based_analyze_for_precalculation(data, args[:company_id].to_i, args[:pid].to_i, args[:gid].to_i)
  end

  def self.calculate_bottlenecks_to_explore(args)
    return AlgorithmsHelper.calculate_bottlenecks_explore(args[:snapshot_id], args[:pid], args[:gid])
  end


  def self.calculate_powerful_non_managers_explore_to_args(args)
    data = AlgorithmsHelper.calculate_powerful_non_managers(args[:snapshot_id], args[:network_id], args[:network_b_id], args[:network_c_id], args[:pid].to_i, args[:gid].to_i)
    return ParamsToArgsHelper.email_based_analyze_for_precalculation(data, args[:company_id].to_i, args[:pid].to_i, args[:gid].to_i)
  end

  def self.calculate_non_reciprocity_between_employees_explore_to_args(args)
    data = AlgorithmsHelper.calculate_non_reciprocity_between_employees_explore(args[:snapshot_id], args[:network_id], args[:network_b_id], args[:pid].to_i, args[:gid].to_i)
    return ParamsToArgsHelper.email_based_analyze_for_precalculation(data, args[:company_id].to_i, args[:pid].to_i, args[:gid].to_i)
  end

  # def self.flag_sinks(args)
  #   return AlgorithmsHelper.flag_sinks(args[:snapshot_id], args[:pid].to_i, args[:gid].to_i)
  # end

  # def self.flag_sinks_explore(args)
  #   return AlgorithmsHelper.flag_sinks_explore(args[:snapshot_id], args[:pid].to_i, args[:gid].to_i)
  # end

  #################### calculate measure helper after functions #############################

  def self.density_of_network(args)
    return AlgorithmsHelper.density_of_network(args[:snapshot_id], args[:gid].to_i, args[:pid].to_i, args[:network_id], args[:network_b_id])
  end

  def self.calculate_embeddednes_of_emails_and_networks(args)
    return AlgorithmsHelper.calculate_embeddednes_of_emails_and_networks(args[:snapshot_id], args[:network_id], args[:network_b_id], args[:network_c_id], args[:pid], args[:gid])
  end

  #################### calculate measure helper after functions #############################

  def self.email_based_analyze_for_precalculation(data, cid, pid, gid)
    remaining_emps = get_all_emps(cid, pid, gid) - data.map { |emp| emp[:id] }
    remaining_emps.each do |node|
      data << { id: node, measure: 0 }
    end
    return data.map { |row| { id: row[:id], measure: row[:measure] * 10 } } if data
    return []
  end

  def self.questionnaire_based_analyze_for_precalculation(data, cid, pid, gid)
    # recent_snapshot_id = sid
    others_id = Employee.where(email: 'other@mail.com').first.try(:id)
    deg_list = []
    remaining_emps = get_all_emps(cid, pid, gid) - data.map { |emp| emp[:id] }
    max = get_max(data)
    data = CalculateMeasureForCustomDataSystemHelper.normalize(data, max) if max != 0
    data.each do |node|
      deg_list << { id: node[:id], measure: node[:measure] }
    end
    remaining_emps.each do |node|
      deg_list << { id: node, measure: 0 }
    end
    return deg_list.delete_if { |r| r[:id] == others_id } unless others_id.nil?
    return deg_list
  end

  def self.calculate_per_snapshot_and_pin(data, sid, pid, gid)
    cid = Snapshot.find(sid).company_id
    others_id = Employee.where(email: 'other@mail.com').first.try(:id)
    deg_list = []
    remaining_emps = get_all_emps(cid, pid, gid) - data.map { |emp| emp[:id] }
    data.each do |node|
      deg_list << { id: node[:id], measure: node[:measure] }
    end
    remaining_emps.each do |node|
      deg_list << { id: node, measure: 0 }
    end
    deg_list.delete_if { |r| r[:id] == others_id } unless others_id.nil?
    # group_max = get_max(deg_list)
    group_max = CdsUtilHelper.get_max(deg_list)
    return CalculateMeasureForCustomDataSystemHelper.normalize(deg_list, group_max)
  end

  def self.calculate_flags(data)
    others_id = Employee.where(email: 'other@mail.com').first.try(:id)
    return data.delete_if { |emp| emp[:id] == others_id } unless others_id.nil?
    return data
  end

  def self.calculate_analyze_scores(data, sid)
    others_id = Employee.where(email: 'other@mail.com').first.try(:id)
    return data.delete_if { |r| r[:id] == others_id } unless others_id.nil?
    return data
  end

  def self.calculate_group_measure_scores(data)
    max = get_max(data)
    return CalculateMeasureForCustomDataSystemHelper.normalize(data, max)
  end

  module_function

  def get_in_or_out_from_args(args)
    return JSON.parse(args[:algorithm_params][:in_or_out])
  end
end
