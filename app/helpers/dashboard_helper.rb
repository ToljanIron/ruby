module DashboardHelper
  NO_SNAPSHOT = -1
  MEANINGFULL = 3
  DIFFRENCE_DYAD = 'Difference dyad'.freeze
  QUARTELY_CHANGE_DYAD = 'Quarterly change dyad'.freeze
  MINUS_SIGN = '-'
  MONTH = 1
  QUARTER = 2
  RELEVANT_GOOD_ALGORITHM_IDS = [401, 402, 403, 404, 405, 406]
  RELEVANT_BAD_ALGORITHM_IDS = []
  MINIMUM_DIFF_TO_SHOW = 20
  NUMBER_OF_EXTREME_RESULTS = 20

  def self.build_tree_map(gid, sid = NO_SNAPSHOT)
    if sid == NO_SNAPSHOT
      company_id = Group.find(gid).company_id
      sid = Snapshot.where(company_id: company_id, snapshot_type: nil).last.id
    end
    groups_arr = CdsGroupsHelper.get_subgroup_ids_only_1_level_deep_with_at_least_5_emps(gid)

    res = CdsMetricScore.where(algorithm_id: RELEVANT_GOOD_ALGORITHM_IDS, group_id: groups_arr, snapshot_id: sid, employee_id: -1).order(score: :desc).limit(5)
    relevant_good_groups_scores = res.map do |e|
      {company_metric_id: e.company_metric_id,
       score:             e.score,
       group_id:          e.group_id}
    end
    relevant_good_groups_scores = add_ui_level_details(relevant_good_groups_scores)

    res = CdsMetricScore.where(algorithm_id: RELEVANT_GOOD_ALGORITHM_IDS, group_id: groups_arr, snapshot_id: sid, employee_id: -1).order(score: :asc).limit(5)
    relevant_bad_groups_scores = res.map do |e|
      {company_metric_id: e.company_metric_id,
       score:             e.score,
       group_id:          e.group_id}
    end
    relevant_bad_groups_scores = add_ui_level_details(relevant_bad_groups_scores)

    return { treemap: { good_scores: relevant_good_groups_scores, bad_scores: relevant_bad_groups_scores } }
  end

  def self.add_ui_level_details(company_metrics)
    company_metrics.map do |cm|
      relevant_ui_level_configuration = UiLevelConfiguration.where(company_metric_id: cm[:company_metric_id]).first
      cm[:level] = relevant_ui_level_configuration.try(:level)
      cm[:display_order] = relevant_ui_level_configuration.try(:display_order)
      cm[:name] = relevant_ui_level_configuration.try(:name)
      cm[:main_tab_name] = UiLevelConfiguration.find(relevant_ui_level_configuration.try(:parent_id)).try(:name)
      cm[:subtabid] = relevant_ui_level_configuration.try(:id)
    end
    return company_metrics
  end

  def self.most_communication_volumes_diff_between_dayds(gid, sid = NO_SNAPSHOT, sign_of_calc = MINUS_SIGN)
    if sid == NO_SNAPSHOT
      cid = Group.find(gid).company_id
      sid = Snapshot.where(company_id: cid, snapshot_type: nil).order('timestamp desc').first.try(:id)
    end
    groups_arr = get_all_level_1_groups_with_employess(gid)
    groups_matrix = create_groups_matrix(groups_arr, sid)
    diff_matrix = create_diff_matrix(groups_matrix, groups_arr, sign_of_calc)
    if sign_of_calc == MINUS_SIGN
      diff_matrix = diff_matrix.select do |dyad|
        sum = dyad[:n_of_emails_to_group] + dyad[:n_of_emails_from_group]
        next if sum.zero?
        (dyad[:diff].abs.to_f / sum.to_f) * 100 > MINIMUM_DIFF_TO_SHOW
      end
    end
    diff_matrix.sort_by! { |dyad| -dyad[:diff].abs }
  end

  def self.communication_volumes_diff_between_dayds_in_2_snapshots(c_v_s1, c_v_s2)
    res = []
    c_v_s1.each do |c_volumes_diff_s1|
      group = c_v_s2.select { |c_volumes_diff_s2| c_volumes_diff_s2[:from_group] == c_volumes_diff_s1[:from_group] && c_volumes_diff_s2[:to_group] == c_volumes_diff_s1[:to_group] }.first
      next unless group
      # || group[:diff].zero?
      # diff = ((c_volumes_diff_s1[:diff] / group[:diff]) * 100) - 100
      new_group = {}
      new_group[:from_group] = group[:from_group]
      new_group[:to_group] = group[:to_group]
      new_group[:total_emails_snapshot_1] = c_volumes_diff_s1[:diff]
      new_group[:total_emails_snapshot_2] = group[:diff]
      new_group[:diff] = c_volumes_diff_s1[:diff] - group[:diff]
      res << new_group
    end
    res = res.sort! { |a, b| a[:diff].abs <=> b[:diff].abs }.reverse!
  end

  def self.create_diff_matrix(groups_matrix, groups_arr, sign_of_calculation)
    groups_with_diff = []
    groups_arr.each_with_index do |group, index|
      groups_arr[index + 1..-1].each do |inner_group|
        from_group_sum = find_sum_of_connection_between_groups(group[:id], inner_group[:id], groups_matrix)
        to_group_sum = find_sum_of_connection_between_groups(inner_group[:id], group[:id], groups_matrix)
        case sign_of_calculation
        when MINUS_SIGN
          diff = from_group_sum - to_group_sum
        else
          diff = from_group_sum + to_group_sum
        end
        groups_with_diff << { from_group: group[:id], to_group: inner_group[:id], n_of_emails_from_group: from_group_sum, n_of_emails_to_group: to_group_sum, diff: diff }
      end
    end
    groups_with_diff = groups_with_diff.sort! { |a| -a[:diff].abs }
  end

  def self.create_groups_matrix(groups_arr, sid)
    company = Snapshot.find(sid).company_id
    network = NetworkSnapshotData.emails(company)
    all_emails_in_snapshot = NetworkSnapshotData.where(snapshot_id: sid, network_id: network)
    groups_matrix = []
    all_emails_in_snapshot.each do |email|
      group_of_emp_from = find_employee_in_groups(email.from_employee_id, groups_arr)
      group_of_emp_to = find_employee_in_groups(email.to_employee_id, groups_arr)
      next if group_of_emp_to.nil? || group_of_emp_from.nil?
      group = groups_matrix.select { |g| g[:from_group] == group_of_emp_from && g[:to_group] == group_of_emp_to }.first
      unless group
        group = { from_group: group_of_emp_from, to_group: group_of_emp_to, sum: 0 }
        groups_matrix << group
      end
      #ASAF BYEBUG something does not seem right in the next line... group[:from_group] should be an array?
      if( (group[:from_group]) === (email.from_employee_id) && (group[:to_group]) === (email.to_employee_id))
        group[:sum] += 1
      end
    end
    groups_matrix
  end

  def self.find_sum_of_connection_between_groups(from_group_id, to_group_id, groups_matrix)
    group = groups_matrix.select { |g| g[:from_group] == from_group_id && g[:to_group] == to_group_id }.first
    return 0 unless group
    group[:sum]
  end

  def self.get_all_level_1_groups_with_employess(gid)
    group_arr = []
    groups_from_level_1 = CdsGroupsHelper.get_subgroup_ids_only_1_level_deep(gid)
    groups_from_level_1.each do |group_id|
      empsarr = Group.find(group_id).extract_employees
      group_arr << { id: group_id, empsarr: empsarr }
    end
    group_arr
  end

  def self.find_employee_in_groups(eid, groups_arr)
    group = groups_arr.select { |g| g[:empsarr].include? eid }.first
    return group unless group
    group[:id]
  end

  def self.fetch_snapshot_from_type(s1, cid, type)
    return unless s1
    snapshot_time = Snapshot.find(s1).timestamp
    case type
    when MONTH
      snapshot_week = (snapshot_time - 1.month).strftime('%Y-%W')
    when QUARTER
      snapshot_week = (snapshot_time - 4.month).strftime('%Y-%W')
    else
      return
    end
    s_2_id = Snapshot.where('company_id = ? and snapshot_type is null and  name like ?', cid, "%#{snapshot_week}%").first.try(:id)
    s_2_id
  end

  def self.calculate_diff_with_last_month(dyad, gid, sid = NO_SNAPSHOT)
    cid = Group.find(gid)[:company_id]
    network = NetworkSnapshotData.emails(cid)
    prev_sid = if sid == NO_SNAPSHOT
                 Snapshot.where(company_id: cid).order('timestamp desc').second.try(:id)
               else
                 Snapshot.where(company_id: cid).where('timestamp < ?', Snapshot.find(sid)[:timestamp]).order('timestamp desc').first.try(:id)
               end

    sum_from =  NetworkSnapshotData.where(snapshot_id: prev_sid, network_id: network, from_employee_id: Group.find(dyad[:from_group]).extract_employees, 
                                    to_employee_id: Group.find(dyad[:to_group]).extract_employees).count
    sum_to =    NetworkSnapshotData.where(snapshot_id: prev_sid, network_id: network, from_employee_id: Group.find(dyad[:to_group]).extract_employees, 
                                    to_employee_id: Group.find(dyad[:from_group]).extract_employees).count
    prev_diff = (sum_from - sum_to).abs
    if prev_diff - dyad[:diff].abs >= 50
      { color: 'orange', text: 'more reciprocal than last month' }
    else
      { color: 'red', text: 'non-reciprocal' }
    end
  end

  def self.create_json_structure(most_communication_volumes, type, s_from_id = nil, s_to_id = nil, cid = nil, direction = nil)
    json_arr = []
    most_communication_volumes.each do |dyads|
      res = {}
      res[:group_from_id] = dyads[:from_group]
      res[:group_to_id] = dyads[:to_group]
      res[:display_type] = type
      res[:company_metric_id] = cid
      res[:direction] = direction
      res[:snapshot_from_id] = s_from_id
      res[:snapshot_to_id] = s_to_id
      res[:order] = dyads[:diff]
      case type
      when DIFFRENCE_DYAD
        res[:total_number_of_emails_between_departments] = { n_of_emails_sent_by_from_group: dyads[:n_of_emails_from_group], n_of_emails_sent_by_to_group: dyads[:n_of_emails_to_group] }
        res[:dynamic_diff] = dyads[:dynamic_diff]
      when QUARTELY_CHANGE_DYAD
        res[:total_emails_snapshot_1] = dyads[:total_emails_snapshot_1]
        res[:total_emails_snapshot_2] = dyads[:total_emails_snapshot_2]
      end
      json_arr << res
    end
    json_arr
  end
end
