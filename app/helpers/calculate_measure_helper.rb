require 'date'
require './app/helpers/advise_measure_helper.rb'
require './app/helpers/friendships_helper.rb'
require './app/helpers/flags_helper.rb'
require './app/helpers/email_snapshot_data_helper.rb'
require './app/helpers/trust_helper.rb'

module CalculateMeasureHelper
  include AdviseMeasureHelper
  include PinsHelper
  include FriendshipsHelper
  include FlagsHelper
  include EmailSnapshotDataHelper
  include UtilHelper
  include TrustHelper

  NUMBER_OF_SNAPSHOTS ||= 50

  NO_PIN   ||= -1
  NO_GROUP ||= -1

  RISK_OF_LEAVING  ||= 0
  PROMISING_TALENT ||= 1
  BYPASSED_MANAGER ||= 2
  GLUE             ||= 3

  NONE          ||= 0
  COLLABORATION ||= 1
  ISOLATED      ||= 2
  SOCIAL        ||= 3
  EXPERT        ||= 4
  CENTRALITY    ||= 5
  CENTRAL       ||= 6
  TRUSTED       ||= 7
  TRUSTING      ||= 8
  IN_THE_LOOP   ||= 9
  POLITICIAN    ||= 10
  TOTAL_ACTIVITY_CENTRALITY ||= 11
  DELEGATOR     ||= 12
  KNOWLEGDE_DISTRIBUTOR     ||= 13
  POLITICALLY_ACTIVE        ||= 14
  OUT_GOING     ||= 15
  EXPANSIVE     ||= 16

  NETWORK_RELATION_LIST ||= ['Friendship', 'Advice', 'Trust', 'Communication flow']

  MEASUREDIRECTION ||= [1, 1, 0, 1]
  SNAPSHOT_WEEKLY  ||= 0
  SNAPSHOT_MONTHLY ||= 1
  SNAPSHOT_YEARLY  ||= 2

  def get_measure_data(companyid, pinid, metrics, gid, snapshot_type)
    fail 'Ambiguous sub-group request with both pin-id and group-id' if pinid != -1 && gid != -1
    pinid = nil if pinid == NO_PIN
    gid = nil if gid == NO_GROUP
    snapshots = Snapshot.where(company_id: companyid, snapshot_type: nil).order('id ASC').limit(NUMBER_OF_SNAPSHOTS)
    begin
      db_all_data = MetricScore.where(company_id: companyid, metric_id: metrics.pluck(:id)).order('score DESC')
    rescue
      db_all_data = []
    end
    res = {}
    metrics.each do |metric|
      data = get_measure_data_per_metric(pinid, gid, metric, db_all_data, snapshots)
      res[metric[:index]] = data if !data.nil? && !data.empty?
    end
    return res
  end

  def get_measure_data_per_metric(pinid, gid, metric, db_all_data, snapshots)
    graph_data = init_graph_data(metric[:index], snapshots.first[:snapshot_type])
    data = { snapshots: {}, graph_data: graph_data }
    prev_norm_calculated_data = nil
    snapshots.each_with_index do |snapshot, index|
      db_data = db_all_data.where(metric_id: metric.id, snapshot_id: snapshot.id, pin_id: pinid, group_id: gid)
      db_company_data = db_all_data.where(metric_id: metric.id, snapshot_id: snapshot.id, group_id: nil, pin_id: nil)
      final_db_data = db_data.map { |row| { id: row[:employee_id], measure: row[:score].to_f } }
      final_db_company_data = db_company_data.map { |row| { id: row[:employee_id], measure: row[:score].to_f } }
      calculate_sd(prev_norm_calculated_data, final_db_data) if index > 0
      root_group = !gid.nil? ? Group.where(id: gid).first.root_group? : false
      if (pinid.nil? && gid.nil?) || root_group
        data[:snapshots][snapshot.id.to_s] = final_db_company_data
        prev_norm_calculated_data = final_db_company_data
        final_db_data = final_db_company_data
      else
        data[:snapshots][snapshot.id.to_s] = final_db_data
        prev_norm_calculated_data = final_db_data
      end
      graph_data[:data][:values] << arrange_per_snapshot(snapshot.id, final_db_data, final_db_company_data)
    end
    if empty_snapshots?(data[:snapshots])
      data = nil
    else
      data[:graph_data] = graph_data
    end
    return data
  end

  def get_flag_data(companyid, pinid, gid, measure_type, _snapshot_type)
    fail 'Ambiguous sub-group request with both pin-id and group-id' if pinid != -1 && gid != -1
    recent_snapshot = Snapshot.where(company_id: companyid, snapshot_type: nil).order(id: :asc).last
    fail "No snapshots in system. can't calculate measure" if recent_snapshot.nil?
    graph_data = flag_init_graph_data(measure_type)
    data = { ret_list: {}, graph_data: graph_data }
    metric_id = Metric.where(metric_type: 'flag', index: measure_type).first.id
    db_data = MetricScore.where(company_id: companyid, metric_id: metric_id, snapshot_id: recent_snapshot.id).select do |row|
      if pinid != NO_PIN
        row[:pin_id] == pinid
      elsif  gid != NO_GROUP && !Group.find(gid).parent_group_id.nil?
        row[:group_id] == gid
      else
        row[:pin_id].nil? && row[:group_id].nil?
      end
    end
    data[:graph_data] = graph_data
    data[:ret_list] = db_data.map { |row| { id: row[:employee_id].to_i } }
    return data
  end

  def get_analyze_data(cid, pid, gid, metrics, sid)
    res = {}
    all_scores_data = fetch_analyze_scores(cid, sid, pid, gid, metrics.pluck(:id))
    metrics.each do |measure|
      questionnaire_metric = [1, 2, 3, 4, 9, 10, 11].include? measure[:index]
      snapshot = Snapshot.find(sid)
      fail "No snapshots in system. can't calculate measure" if snapshot.nil?
      dt = snapshot.timestamp.to_i
      snapshot_date = snapshot.timestamp.strftime('%b %Y')
      scores_data = all_scores_data.select { |m| m[:metric_id] == measure.id }
      employee_scores_hash = scores_data.map { |row| { id: row[:employee_id], rate: row[:score].to_f * 10 } }
      max_score = employee_scores_hash.map { |row| row[:rate] }.max
      normalize_by_attribute(employee_scores_hash, :rate, 100) unless questionnaire_metric
      if employee_scores_hash.empty? || (max_score == 0 && !questionnaire_metric)
        data = { degree_list: [], measure_name: measure[:name], measure_id: measure[:index] }
      else
        data = { degree_list: employee_scores_hash, dt: dt * 1000, date: snapshot_date, measure_name: measure[:name], measure_id: measure[:index] }
      end
      res[measure[:index]] = data if !data.nil? && data[:degree_list].length > 0
    end
    return res
  end

  def get_collaboration_data(cid, eid)
    sid = Snapshot.where(company_id: cid, snapshot_type: nil).order(id: :asc).last.id
    emps_in_pin = get_employee_connection(sid, false, eid)
    create_edges_array_for_email_analyze(emps_in_pin, false)
  end

  def get_snapshot_list(cid)
    snapshot_list = Snapshot.where(company_id: cid, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order(timestamp: :desc)
    res = []
    snapshot_list.each_with_index do |snapshot|
      time = snapshot.timestamp.strftime('W-%V')+'  ' + week_start(snapshot.timestamp).gsub('.', '/') + ' - ' + week_end(snapshot.timestamp).gsub('.', '/')
      res.push(sid: snapshot.id, name: snapshot.name, time: time)
    end
    return res
  end

  def week_start(date)
    (date.beginning_of_week - 1).strftime('%d.%m.%y')
  end

  def week_end(date)
    (date.end_of_week - 1).strftime('%d.%m.%y')
  end

  def get_network_relations_data(_cid, pid, gid, sid)
    res = {}
    snapshot = Snapshot.find(sid)
    fail "No snapshots in system. can't calculate measure" if snapshot.nil?
    NETWORK_RELATION_LIST.each_with_index do |relation, index|
      data = get_data_to_relation(relation, sid, pid, gid)
      res[index] = { relation: data, name: relation, network_index: index } if !data.nil? && (data.length > 0 || relation != 'Communication flow')
    end
    return res
  end

  def get_group_measure_data(cid, gid, metric)
    result = { snapshots: {}, graph_data: { data: { values: [] } } }
    gid = Group.where(company_id: cid, parent_group_id: nil).pluck(:id) if gid.nil?
    subgroups = Group.where(parent_group_id: gid).pluck(:id)
    return nil if subgroups.empty?
    data = MetricScore.where(metric_id: metric.id, company_id: cid, subgroup_id: subgroups.to_a).order('score DESC')
    return nil if data.map { |row| row[:score] }.max == 0
    Snapshot.where(company_id: cid, snapshot_type: nil).order(id: :asc).pluck(:id).each do |snapshot_id|
      snapshot_data = data.select { |record| record[:snapshot_id] == snapshot_id }.map do |record|
        { main_group_id: record[:group_id], group_id: record[:subgroup_id], score: record[:score].to_f }
      end
      next if snapshot_data.empty?
      company_data = snapshot_data.select { |record| record[:main_group_id].nil? }
      snapshot_data.delete_if { |record| record[:main_group_id].nil? }
      snapshot_average = snapshot_data.inject(0) { |a, e| a + e[:score] } / snapshot_data.length
      company_snapshot_average = company_data.inject(0) { |a, e| a + e[:score] } / company_data.length
      result[:snapshots][snapshot_id.to_s] = snapshot_data
      result[:graph_data][:data][:values] << [snapshot_id, snapshot_average.round(2), company_snapshot_average.round(2)]
    end
    result[:graph_data][:measure_name] = metric[:name]
    return result unless result[:snapshots].empty?
    return
  end

  def get_play_to_metric(cid, gid, pid, network_id, measure_id)
    measure_to_kl = {}
    snapshot_dt_list = []
    relation_to_kl = {}
    snapshot_list = Snapshot.where(company_id: cid, snapshot_type: nil)
    snapshot_list.each_with_index do |snapshot|
      data = get_analyze_data(cid, pid, gid, measure_id, snapshot.id)
      current_measure = data if !data.nil? && data[:degree_list].length > 0
      add_metric_score_from_snapshot(current_measure, measure_to_kl)
      relation_name = NETWORK_RELATION_LIST[network_id]
      relation = get_data_to_relation(relation_name, snapshot.id, pid, gid)
      snapshot_dt_list << current_measure[:dt]
      add_relation_from_snapshot(relation, relation_to_kl, relation_name, network_id)
    end
    return { measure: measure_to_kl,  network: relation_to_kl, snapshot_dt_list: snapshot_dt_list }
  end

  # *** for precalculate_metric_scores task ***

  def add_metric_score_from_snapshot(current_snapshot, measure_all_snapshot)
    measure_all_snapshot[:measure_name] = current_snapshot[:measure_name]
    measure_all_snapshot[:measure_id] = current_snapshot[:measure_id]
    measure_all_snapshot[:date] = current_snapshot[:date]
    measure_all_snapshot[:degree_list] = current_snapshot[:degree_list] if measure_all_snapshot[:degree_list].nil?
    current_snapshot[:degree_list].each do |emp_from_current_snapshot|
      employee = measure_all_snapshot[:degree_list].select { |emp_from_all| emp_from_all[:id] == emp_from_current_snapshot[:id] }.first
      add_dt_and_score_to_employee(employee, current_snapshot, emp_from_current_snapshot)
    end
    return measure_all_snapshot
  end

  def add_relation_from_snapshot(current_relation, relation_from_all_snapshot, relation_name, nid)
    relation_from_all_snapshot[:name] = relation_name
    relation_from_all_snapshot[:network_index] = nid
    relation_from_all_snapshot[:relation] = current_relation if relation_from_all_snapshot[:relation].nil?
    current_relation.each do |relation_from_current_snapshot|
      rel = relation_from_all_snapshot[:relation].select do |rel_from_all|
        rel_from_all[:from_emp_id] == relation_from_current_snapshot[:from_emp_id] &&  rel_from_all[:to_emp_id] == relation_from_current_snapshot[:to_emp_id]
      end
      if rel.first
        add_dt_and_rel_to_employee(rel.first, relation_from_current_snapshot)
      else
        relation_from_all_snapshot[:relation] << relation_from_current_snapshot
        add_dt_and_rel_to_employee(relation_from_all_snapshot[:relation].last, relation_from_current_snapshot)
      end
    end
  end

  def add_dt_and_rel_to_employee(rel, relation_from_current_snapshot)
    return unless rel
    if rel[:dt_list]
      rel[:dt_list] << relation_from_current_snapshot[:dt]
      rel[:score_list] << relation_from_current_snapshot[:weight]
    else
      rel[:dt_list] = [relation_from_current_snapshot[:dt]]
      rel[:score_list] = [relation_from_current_snapshot[:weight]]
    end
  end

  def add_dt_and_score_to_employee(employee, current_snapshot, emp_from_current_snapshot)
    return unless employee
    if employee[:dt_list]
      employee[:dt_list] << current_snapshot[:dt]
      employee[:score_list] << emp_from_current_snapshot[:rate]
    else
      employee[:dt_list] = [current_snapshot[:dt]]
      employee[:score_list] = [emp_from_current_snapshot[:rate]]
    end
  end

  def calculate_measure_scores(cid, sid, pid, gid, measure_type)
    res = calculate_per_snapshot_and_pin(cid, sid, pid, measure_type, gid)
    group_max = get_max(res)
    return normalize(res, group_max)
  end

  def calculate_flags(cid, sid, pid, gid, flag_type)
    others_id = Employee.where(email: 'other@mail.com').first.try(:id)
    case flag_type
    when 0
      res = get_likely_flag(cid, sid, pid, gid)
    when 1
      res = most_promising(cid, sid, pid, gid)
    when 2
      res = most_bypassed_manager(cid, sid, pid, gid)
    when 3
      # res = team_glue(cid, sid, pid, gid)   DEAD CODE BYEBUG asaf
    end
    return res.delete_if { |emp| emp[:id] == others_id } unless others_id.nil?
    return res
  end

  def calculate_analyze_scores(cid, sid, pid, gid, analyze_type)
    # recent_snapshot_id = Snapshot.where(company_id: cid).order('id ASC').last.id
    recent_snapshot_id = sid
    others_id = Employee.where(email: 'other@mail.com').first.try(:id)
    if [1, 2, 3, 4, 9, 10, 11].include? analyze_type # friendship, social power, expert, trust
      res = questionnaire_based_analyze_for_precalculation(cid, recent_snapshot_id, pid, gid, analyze_type)
    else # email metrics, including collaboration
      res = email_based_analyze_for_precalculation(cid, recent_snapshot_id, pid, gid, analyze_type)
    end
    return res.delete_if { |r| r[:id] == others_id } unless others_id.nil?
    return res
  end

  def get_measures_per_employee(cid, employee_id)
    snapshots = Snapshot.where(company_id: cid, snapshot_type: nil).order(id: :asc)
    last_snapshot_id = snapshots.last.id
    metrics = Metric.where(metric_type: 'measure')
    metric_ids = metrics.pluck(:id).to_a
    employee_measure_scores = MetricScore.where(employee_id: employee_id, snapshot_id: last_snapshot_id, group_id: nil, pin_id: nil, metric_id: metric_ids).pluck(:score, :metric_id)
    if snapshots.length > 1
      previous_snapshot_id = snapshots[-2].id
      previous_scores = MetricScore.where(employee_id: employee_id, snapshot_id: previous_snapshot_id, group_id: nil, pin_id: nil, metric_id: metric_ids).pluck(:score, :metric_id)
      metric_ids.each do |metric_id|
        pair = employee_measure_scores.rassoc(metric_id)
        next unless pair
        previous_pair = previous_scores.rassoc(metric_id) || [0, 0]
        trend = pair[0] - previous_pair[0] < 0
        pair.push(trend)
      end
    end
    return employee_measure_scores.map { |row| { name: metrics.find(row[1])[:name], rate: row[0], trend: row[2] } }
  end

  private

  def get_data_to_relation(relation, sid, pid, gid)
    case relation
    when 'Friendship' # friendships
      data = calculate_pair_friendships_per_snapshot(sid, pid, gid)
    when 'Advice' # advice expert
      data = calculate_pair_advice_per_snapshot(sid, pid, gid)
    when 'Trust' # trust
      data = calculate_pair_trusted_per_snapshot(sid, pid, gid)
    else # email metrics
      data = calculate_pair_emails_per_snapshot(sid, pid, gid)
    end
    return data
  end

  def calculate_pair_emails_per_snapshot(sid, pid, gid)
    emps_in_pin = get_snapshot_node_list(sid, false, pid, gid)
    snapshot = Snapshot.find(sid)
    dt = snapshot.timestamp.to_i * 1000
    create_edges_array_for_email_analyze(emps_in_pin, true, dt)
  end

  def email_based_analyze_for_precalculation(cid, recent_snapshot_id, pid, gid, analyze_type)
    case analyze_type
    when 0
      return collaboration_for_precalculation(cid, recent_snapshot_id, pid, gid)
    when 5
      key = "centrality_#{recent_snapshot_id}_#{gid}_#{pid}"
      ret = read_or_calculate_and_write(key) { centrality(recent_snapshot_id, gid, pid) }
    when 6
      key = "central_#{recent_snapshot_id}_#{gid}_#{pid}"
      ret = read_or_calculate_and_write(key) { central(recent_snapshot_id, gid, pid) }
    when 7
      key = "in_the_loop_#{recent_snapshot_id}_#{gid}_#{pid}"
      ret = read_or_calculate_and_write(key) { in_the_loop(recent_snapshot_id, gid, pid) }
    when 8
      key = "politician_#{recent_snapshot_id}_#{gid}_#{pid}"
      ret =  read_or_calculate_and_write(key) { politician(recent_snapshot_id, gid, pid) }
    end
    remaining_emps = get_all_emps(cid, pid, gid) - ret.map { |emp| emp[:id] }
    remaining_emps.each do |node|
      ret << { id: node, measure: 0 }
    end
    return ret.map { |row| { id: row[:id], measure: row[:measure] * 10 } } if ret
    return []
  end

  def questionnaire_based_analyze_for_precalculation(cid, recent_snapshot_id, pid, gid, analyze_type)
    case analyze_type
    when 1 # friendship
      metric_array = get_f_in_n(recent_snapshot_id, pid, gid)
    when 2 # social power
      metric_array = get_most_social(recent_snapshot_id, pid, gid)
    when 3 # expert
      metric_array = get_a_in_n(recent_snapshot_id, pid, gid)
    when 4 # Most Trusted
      metric_array = get_t_in_n(recent_snapshot_id, pid, gid)
    when 9 # Most Trusting
      metric_array = get_t_out_n(recent_snapshot_id, pid, gid)
    when 10 # Out Going
      metric_array = get_f_out_n(recent_snapshot_id, pid, gid)
    when 11 # Expansive
      metric_array = get_a_out_n(recent_snapshot_id, pid, gid)
    end
    deg_list = []
    remaining_emps = get_all_emps(cid, pid, gid) - metric_array.map { |emp| emp[:id] }
    max = get_max(metric_array)
    metric_array = normalize(metric_array, max) if max != 0
    metric_array.each do |node|
      deg_list << { id: node[:id], measure: node[:measure] }
    end
    remaining_emps.each do |node|
      deg_list << { id: node, measure: 0 }
    end
    return deg_list
  end

  def collaboration_for_precalculation(cid, recent_snapshot_id, pid, gid)
    key = "get_snapshot_node_list_#{recent_snapshot_id}_false_#{pid}_#{gid}"
    ret = read_or_calculate_and_write(key) do
      emps_in_pin = get_snapshot_node_list(recent_snapshot_id, false, pid, gid)
      create_measure_list(emps_in_pin, true, pid, gid, cid)
    end
    return ret.map { |row| { id: row[:id], measure: row[:rate] / 10 } } if ret
    return []
  end

  def fetch_analyze_scores(cid, sid, pid, gid, metric_ids)
    pid = nil if pid == NO_PIN
    gid = nil if gid == NO_GROUP || Group.find(gid).parent_group_id.nil?
    db_data = MetricScore.where(company_id: cid, snapshot_id: sid, metric_id: metric_ids, pin_id: pid, group_id: gid)
    return db_data
  end

  def init_graph_data(index, snapshot_type)
    months = snapshot_type == 1 ? 1 : 12
    metric = Metric.where(metric_type: 'measure', index: index).first
    return {
      measure_name: metric[:name],
      last_updated: time_now,
      avg: nil,
      trend: false,
      negative: MEASUREDIRECTION[index],
      data: {
        delta_size_in_months: months,
        values: []
      }
    }
  end

  def empty_snapshots?(snapshots)
    snapshots.each do |_key, snapshot|
      return false if snapshot.length > 0 && snapshot.map { |el| el[:measure] }.max != 0
    end
    return true
  end

  def flag_init_graph_data(measure_type)
    time = DateTime.parse(Time.now.to_s).strftime('%B %d, %Y')
    metric = Metric.where(metric_type: 'flag', index: measure_type).first
    return {
      measure_name: metric[:name],
      last_updated: time
    }
  end

  def time_now
    time = Time.now.to_s
    return DateTime.parse(time).strftime('%d/%m/%Y')
  end

  def arrange_per_snapshot(snapshot_id, calculated_data, company_calculated_data)
    pin_avg = 0
    if calculated_data.length != 0
      pin_avg = calculated_data.inject(0) { |memo, n|  memo + (n[:measure] || n[:score]) } / calculated_data.length
      pin_avg = pin_avg.round(2)
    end
    company_avg = 0
    if company_calculated_data.length != 0
      company_avg = company_calculated_data.inject(0) { |memo, n|  memo + (n[:measure] || n[:score]) } / company_calculated_data.length
      company_avg = company_avg.round(2)
    end
    return [
      snapshot_id,
      pin_avg,
      company_avg
    ]
  end

  def calculate_sd(prev_snapshot, current_snapshot)
    return if prev_snapshot == []  ## HACK - MUST FIX
    vector = []
    current_snapshot.each do |emp_details|
      prev_measure = prev_snapshot.select { |emp| emp[:id] == emp_details[:id] }
      if prev_measure.length != 0
        prev = prev_measure.first[:measure]
      else
        prev = 0
      end
      vector << emp_details[:measure] - prev
    end
    stats = DescriptiveStatistics::Stats.new(vector)
    standard_deviation = stats.standard_deviation
    mean = stats.mean
    add_pending_attention_flag(current_snapshot, standard_deviation, vector, mean)
  end

  def add_pending_attention_flag(current_snapshot, standard_deviation, vector, mean)
    return nil unless standard_deviation
    distance = 2 * standard_deviation
    current_snapshot.each_with_index do |emp, index|
      emp[:pay_attention_flag] = false
      next if distance.nan? || !distance
      if vector[index] > mean + distance || vector[index] < mean - distance
        emp[:pay_attention_flag] = true
      end
    end
  end

  def calculate_per_snapshot_and_pin(companyid, snapshotid, pinid, measure_type, gid)
    others_id = Employee.where(email: 'other@mail.com').first.try(:id)
    ret = nil
    case measure_type
    when COLLABORATION
      key = "get_snapshot_node_list_#{snapshotid}_false_#{pinid}_#{gid}"
      ret = read_or_calculate_and_write(key) do
        emps_in_pin = get_snapshot_node_list(snapshotid, false, pinid, gid)
        emps_in_pin.rows.empty? ? [] : create_measure_list(emps_in_pin, true, pinid, gid, companyid)
      end
    when ISOLATED
      ret = get_f_in_n(snapshotid, pinid, gid)

      # ret = most_isolated(snapshotid, pinid, gid)
    when SOCIAL
      ret = get_most_social(snapshotid, pinid, gid)
    when EXPERT
      ret = find_most_expert(snapshotid, pinid, gid)
    when CENTRALITY
      key = "centrality_#{snapshotid}_#{gid}_#{pinid}"
      ret = read_or_calculate_and_write(key) { centrality(snapshotid, gid, pinid) }
    when CENTRAL
      key = "central_#{snapshotid}_#{gid}_#{pinid}"
      ret = read_or_calculate_and_write(key) { central(snapshotid, gid, pinid) }
    when IN_THE_LOOP
      key = "in_the_loop_#{snapshotid}_#{gid}_#{pinid}"
      ret = read_or_calculate_and_write(key) { in_the_loop(snapshotid, gid, pinid) }
    when POLITICIAN
      key = "politician_#{snapshotid}_#{gid}_#{pinid}"
      ret = read_or_calculate_and_write(key) { politician(snapshotid, gid, pinid) }
    when TOTAL_ACTIVITY_CENTRALITY
      ret = total_activity_centrality(snapshotid, gid, pinid)
    when DELEGATOR
      ret = delegator(snapshotid, gid, pinid)
    when KNOWLEGDE_DISTRIBUTOR
      ret = knowledge_distributor(snapshotid, gid, pinid)
    when POLITICALLY_ACTIVE
      ret = politically_active(snapshotid, gid, pinid)
    when TRUSTED
      ret = get_t_in_n(snapshotid, pinid, gid).sort_by { |k| k[:measure] }.reverse
    when TRUSTING
      ret = get_t_out_n(snapshotid, pinid, gid).sort_by { |k| k[:measure] }.reverse
    when OUT_GOING
      ret = get_f_out_n(snapshotid, pinid, gid)
    when EXPANSIVE
      ret = get_a_out_n(snapshotid, pinid, gid)
    end
    deg_list = []
    remaining_emps = get_all_emps(companyid, pinid, gid) - ret.map { |emp| emp[:id] }
    ret.each do |node|
      deg_list << { id: node[:id], measure: node[:measure] }
    end
    remaining_emps.each do |node|
      deg_list << { id: node, measure: 0 }
    end
    return deg_list.delete_if { |r| r[:id] == others_id } unless others_id.nil?
    return deg_list
  end


  def normalize(arr, max)
    if max == 0
      arr.each do |o|
        o[:measure] = max.round(2)
      end
    else
      arr.each do |o|
        o[:measure] = (10 * o[:measure].to_f / max.to_f).round(2)
      end
    end
  end

  def normalize_by_attribute(arr, attribute, factor)
    maximum = arr.map { |elem| elem["#{attribute}".to_sym] }.max
    return arr if maximum == 0
    arr.each do |o|
      o["#{attribute}".to_sym] = (factor * o["#{attribute}".to_sym] / maximum.to_f).round(2)
    end
  end

  def create_edges_array_for_email_analyze(emps, normalize = true, dt = nil)
    relation_arr = []
    snapshots_as_hash = emps.to_hash
    weights = weight_algorithm(emps, normalize)
    snapshots_as_hash.each_with_index do |node, index|
      from_emp = node['employee_from_id'].to_i
      to_emp = node['employee_to_id'].to_i
      weight = weights[index]
      relation_arr << { from_emp_id: from_emp, to_emp_id: to_emp, weight: weight, dt: dt }
    end
    return relation_arr
  end
end
