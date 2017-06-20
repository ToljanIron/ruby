# frozen_string_literal: true
require 'date'
require './app/helpers/algorithms_helper.rb'
require './app/helpers/email_snapshot_data_helper.rb'
# require './app/helpers/email_traffic_helper.rb'
require './app/helpers/email_traffic_helper_OLD.rb'
require './app/helpers/calculate_measure_for_custom_data_system_helper.rb'

module CalculateMeasureForCustomDataSystemHelper
  NUMBER_OF_SNAPSHOTS ||= 12

  NO_PIN   ||= -1
  NO_GROUP ||= -1

  SNAPSHOT_WEEKLY ||= 0

  EMAIL   ||= 2

  MEASURE ||= 1
  FLAG    ||= 2
  ANALYZE ||= 3
  GROUP   ||= 4
  GAUGE   ||= 5
  QUESTIONNAIRE_ONLY ||= 8

  def cds_get_measure_data_for_questionnaire_only(cid, gid)
    groupid_condition = "group_id = #{gid} AND "
    sid = Snapshot.where(company_id: cid, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order('id ASC').pluck(:id).last
    company_metrics = CompanyMetric.where(company_id: cid, algorithm_id: [601, 602])
    company_metric_by_id = {}
    company_metrics.each { |e| company_metric_by_id[e.id.to_s] = e }

    sqlstr = "
      SELECT nn.name AS metric_name, employee_id, group_id, snapshot_id, company_metric_id, score, cds.algorithm_id
      FROM cds_metric_scores AS cds
      JOIN company_metrics AS cm ON cm.id = cds.company_metric_id
      JOIN algorithms AS al ON al.id = cm.algorithm_id
      JOIN network_names AS nn ON nn.id = cm.network_id
      WHERE
        cds.snapshot_id = #{sid} AND
        #{groupid_condition}
        cds.algorithm_id IN (601, 602)
      ORDER BY snapshot_id, company_metric_id, score DESC"

    cds_scores = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    res = {}
    cds_scores.each do |cds_score|
      metric_name = CompanyMetric.generate_metric_name_for_questionnaire_only(cds_score['metric_name'], cds_score['algorithm_id'])
      company_metric = company_metric_by_id[cds_score['company_metric_id'].to_s]
      sid            = cds_score['snapshot_id'].to_i
      eid            = cds_score['employee_id'].to_i
      measure        = cds_score['score'].to_f
      group_id       = cds_score['group_id']
      entry          = { id: eid, measure: measure, pay_attention_flag: false }

      measure_res, res                  = res.fetch_or_create(metric_name) { create_measure_result_data_structre(company_metric, metric_name) }
      snapshot, measure_res[:snapshots] = measure_res[:snapshots].fetch_or_create(sid) { [] } unless group_id.nil?

      snapshot << entry
    end

    res.keys.each do |metric_name|
      group_data = res[metric_name][:snapshots][sid]
      res[metric_name][:graph_data][:data][:values] << arrange_per_each_snapshot(sid, group_data)
    end

    return res
  end

  def create_measure_result_data_structre(company_metric, metric_name)
    graph_data = cds_init_graph_data(company_metric.metric_id, metric_name)
    data = { snapshots: {}, graph_data: graph_data }
    data[:company_metric_id] = company_metric.id
    data[:analyze_company_metric_id] = company_metric.analyze_company_metric_id
    return data
  end

  def cds_get_measure_data(companyid, pinid, algorithms_ids, gid)
    raise 'Ambiguous sub-group request with both pin-id and group-id' if pinid != -1 && gid != -1
    groupid = gid == NO_GROUP ? pinid : gid
    groupid_condition = "group_id = #{groupid} AND "

    sids = Snapshot.where(company_id: companyid, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order('id ASC').limit(NUMBER_OF_SNAPSHOTS).pluck(:id)

    company_metrics = CompanyMetric.where(company_id: companyid, algorithm_id: algorithms_ids)
    company_metric_by_id = {}
    company_metrics.each { |e| company_metric_by_id[e.id.to_s] = e }

    sqlstr = "
      SELECT met.name AS metric_name, employee_id, group_id, snapshot_id, company_metric_id, score, cds.algorithm_id
      FROM cds_metric_scores AS cds
      JOIN company_metrics AS cm ON cm.id = cds.company_metric_id
      JOIN metric_names AS met ON met.id = cm.metric_id
      WHERE
        cds.snapshot_id IN (#{sids.join(',')}) AND
        #{groupid_condition}
        cds.algorithm_id IN (#{algorithms_ids.join(',')})
      ORDER BY snapshot_id, company_metric_id, score DESC"

    cds_scores = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    res = {}
    cds_scores.each do |cds_score|
      metric_name    = cds_score['metric_name']
      company_metric = company_metric_by_id[cds_score['company_metric_id'].to_s]
      sid            = cds_score['snapshot_id'].to_i
      eid            = cds_score['employee_id'].to_i
      measure        = cds_score['score'].to_f
      group_id       = cds_score['group_id']
      entry          = { id: eid, measure: measure, pay_attention_flag: false }

      ## Next few lines may look a little odd at first but all they do is prepare
      ##   a place to shove the entry.  At first the required arrays are not there
      ##   so they will be created on the fly using fetch_or_create.
      measure_res, res                  = res.fetch_or_create(metric_name) { create_measure_result_data_structre(company_metric, metric_name) }
      snapshot, measure_res[:snapshots] = measure_res[:snapshots].fetch_or_create(sid) { [] } unless group_id.nil?
      snapshot << entry
    end

    res.keys.each do |metric_name|
      sids.each do |sid|
        group_data = res[metric_name][:snapshots][sid]
        puts "Working on metric: #{metric_name}"
        res[metric_name][:graph_data][:data][:values] << arrange_per_each_snapshot(sid, group_data)
      end
    end

    return res
  end

  def arrange_per_each_snapshot(snapshot_id, calculated_data)
    pin_avg = 0
    unless calculated_data.empty?
      pin_avg = calculated_data.inject(0) { |memo, n| memo + (n[:measure] || n[:score]) } / calculated_data.length
      pin_avg = pin_avg.round(2)
    end
    return [
      snapshot_id.to_i,
      pin_avg
    ]
  end

  def cds_init_graph_data(_metric_id, metric_name)
    return {
      measure_name: metric_name,
      last_updated: time_now,
      avg: nil,
      trend: false,
      negative: 1,
      type: 'measure',
      data: {
        delta_size_in_months: 12,
        values: []
      }
    }
  end

  def cds_get_flag_data(companyid, pinid, gid, cm)
    raise 'Ambiguous sub-group request with both pin-id and group-id' if pinid != -1 && gid != -1
    recent_snapshot = Snapshot.where(company_id: companyid, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order(id: :asc).last
    raise "No snapshots in system. can't calculate measure" if recent_snapshot.nil?
    graph_data = cds_flag_init_graph_data(cm.metric_id, 'flag')
    data = { ret_list: {}, graph_data: graph_data }
    groups = [gid]
    db_data = CdsMetricScore.where(company_id: companyid, algorithm_id: cm.algorithm_id, snapshot_id: recent_snapshot.id).select do |row|
      if pinid != NO_PIN
        row[:pin_id] == pinid && row[:score] != 0.to_f
      elsif gid != NO_GROUP # && (gid != top_group_id)
        groups.include?(row[:group_id]) && row[:score] != 0.to_f
      else
        row[:pin_id].nil? && row[:group_id].nil? && row[:score] != 0.to_f
      end
    end
    data[:company_metric_id] = cm.id
    data[:analyze_company_metric_id] = cm.analyze_company_metric_id
    data[:graph_data] = graph_data
    data[:name] = graph_data[:measure_name]
    pos_doubles = db_data.map { |row| { id: row[:employee_id].to_i } }
    data[:ret_list] = screen_doubles(pos_doubles)
    data[:ret_list] = data[:ret_list].take(50)
    return data
  end

  def screen_doubles(arr)
    new_arr = []
    arr.each do |doub|
      new_arr.push(doub) unless new_arr.include?(doub)
    end
    return new_arr
  end

  def cds_get_gauge_data(companyid, pinid, gid, cm)
    raise 'Ambiguous sub-group request with both pin-id and group-id' if pinid != -1 && gid != -1
    recent_snapshot = Snapshot.where(company_id: companyid, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order(id: :asc).last
    raise "No snapshots in system. can't calculate measure" if recent_snapshot.nil?
    graph_data = cds_flag_init_graph_data(cm.metric_id, 'gauge')
    data = { graph_data: graph_data }
    group_id = (gid == NO_GROUP ? pinid : gid)
    gauge_value = get_gauge_value(companyid, cm, cm.algorithm_id, recent_snapshot.id, group_id)
    gauge_params = calculate_and_save_gauge_parameters(companyid, cm.algorithm_id, recent_snapshot.id, cm)
    data[:company_metric_id] = cm.id
    data[:analyze_company_metric_id] = cm.analyze_company_metric_id
    data[:rate]             = gauge_value.nil? ? -1 : gauge_value[:score]
    data[:min_range]        = gauge_params[:min_range]
    data[:min_range_wanted] = gauge_params[:min_range_wanted]
    data[:max_range]        = gauge_params[:max_range]
    data[:max_range_wanted] = gauge_params[:max_range_wanted]
    data[:background_color] = gauge_params[:background_color]
    data[:algorithm_id]     = cm.algorithm_id
    data[:algorithm_name]   = cm.algorithm.name
    return data
  end

  def get_gauge_value(cid, cm, aid, sid, gid)
    gauge_value = CdsMetricScore.where(company_id: cid, company_metric_id: cm.id, algorithm_id: aid, snapshot_id: sid, group_id: gid).last
    return gauge_value
  end

  # If the gauge parameters are already in the database then return them
  # Otherwise calculate them, save in db and return
  def calculate_and_save_gauge_parameters(cid, aid, sid, company_metric)
    gauge_configuration = company_metric.gauge_configuration
    # if gauge_configuration.configuration_is_empty?
    gauge_params = AlgorithmsHelper.calculate_gauge_parameters(cid, aid, sid, company_metric.id)
    # If the minimum and maximum settings are set in the database then we need
    # to copy them and re-scale the mid-range values
    if gauge_configuration.configuration_is_preconfigured?
      oldmin    = gauge_params[:min_range]
      oldmax    = gauge_params[:max_range]
      oldmidmin = gauge_params[:min_range_wanted]
      oldmidmax = gauge_params[:max_range_wanted]

      newmin = gauge_configuration.static_minimum
      newmax = gauge_configuration.static_maximum

      gauge_params[:min_range] = gauge_configuration.static_minimum
      gauge_params[:max_range] = gauge_configuration.static_maximum
      min_range_wanted = newmin + ((oldmidmin - oldmin).to_f * (newmax - newmin).to_f / (oldmax - oldmin).to_f).round(2)
      max_range_wanted = newmin + ((oldmidmax - oldmin).to_f * (newmax - newmin).to_f / (oldmax - oldmin).to_f).round(2)
      if min_range_wanted.nan?
        min_range_wanted = -0.5
        max_range_wanted = 0.5
      end
      gauge_params[:min_range_wanted] = min_range_wanted
      gauge_params[:max_range_wanted] = max_range_wanted
    end
    gauge_configuration.populate(gauge_params, cid)
    return gauge_params
    # end
  end

  def cds_get_analyze_data_questionnaire_only(cid, pid, gid, company_metrics, sid)
    res = {}
    all_scores_data = cds_fetch_analyze_scores(cid, sid, pid, gid, company_metrics.pluck(:id))
    snapshot = Snapshot.find(sid)
    raise "No snapshots in system. can't calculate measure" if snapshot.nil?
    dt = snapshot.timestamp.to_i
    snapshot_date = snapshot.timestamp.strftime('%b %Y')

    company_metrics.each do |cm|
      scores_data = all_scores_data.select { |m| m[:company_metric_id] == cm.id }
      employee_scores_hash = scores_data.map { |row| { id: row[:employee_id], rate: row[:score].to_f * 10 } }
      employee_scores_hash = normalize_by_attribute(employee_scores_hash, :rate, 100)
      network_ids = [cm.network_id]
      uil_id      = CompanyMetric.generate_ui_level_id_for_questionnaire_only(cm.id)
      metric_name = CompanyMetric.generate_metric_name_for_questionnaire_only(cm.network.name, cm.algorithm_id)

      res[uil_id] = {
        degree_list: employee_scores_hash,
        dt: dt * 1000,
        date: snapshot_date,
        measure_name: metric_name,
        measure_id: cm.id,
        network_ids: network_ids
      }
    end
    return res
  end

  def cds_get_analyze_data(cid, pid, gid, company_metrics, sid)
    res = {}
    all_scores_data = cds_fetch_analyze_scores(cid, sid, pid, gid, company_metrics.pluck(:id))
    snapshot = Snapshot.find(sid)
    raise "No snapshots in system. can't calculate measure" if snapshot.nil?
    dt = snapshot.timestamp.to_i
    snapshot_date = snapshot.timestamp.strftime('%b %Y')

    company_metrics.each do |cm|
      scores_data = all_scores_data.select { |m| m[:company_metric_id] == cm.id }
      employee_scores_hash = scores_data.map { |row| { id: row[:employee_id], rate: row[:score].to_f * 10 } }
      employee_scores_hash = normalize_by_attribute(employee_scores_hash, :rate, 100)
      network_ids = get_network_list_to_compay_mertic(cm)
      metric_names = get_ui_level_names(cm)
      metric_names.each do |uil_id, metric_name|
        data = if employee_scores_hash.empty?
                 { degree_list: [], measure_name: metric_name, measure_id: cm.algorithm_id, network_ids: network_ids }
               else
                 { degree_list: employee_scores_hash, dt: dt * 1000, date: snapshot_date, measure_name: metric_name, measure_id: cm.id, network_ids: network_ids }
               end
        res[uil_id] = data if !data.nil? && !data[:degree_list].empty?
      end
    end
    return res
  end

  def get_questionnaire_algorithms(algorithm_id)
    algorithm = Algorithm.find_by(id: algorithm_id)
    return !algorithm.nil? && algorithm.algorithm_type_id == 3 && algorithm.algorithm_flow_id == 1
  end

  def cds_get_network_and_metric_names(cid, algorithm_type_id)
    res = {}
    relevant_company_metrics = CompanyMetric.where(company_id: cid, algorithm_type_id: algorithm_type_id)
    relevant_company_metrics.each do |company_metric|
      network_name = get_network_name(company_metric.network_id)
      metric_name = get_metric_name(company_metric.metric_id)
      if res.keys.include?(network_name)
        next if res[network_name].include?(metric_name)
        res[network_name] = res[network_name].push(metric_name)
        next
      end
      res[network_name] = [metric_name]
    end
    return res
  end

  def cds_get_flagged_employees(cid, gid, company_metric_id, sid)
    algorithm_id = CompanyMetric.find(company_metric_id).algorithm_id
    return CdsMetricScore.where(algorithm_id: algorithm_id, company_id: cid, group_id: gid, snapshot_id: sid).where('score != ?', 0).pluck(:employee_id).uniq
  end

  def get_network_name(network_id)
    return NetworkName.where(id: network_id).first.name
  end

  def get_metric_name(metric_id)
    return MetricName.where(id: metric_id).first.name
  end

  def get_network_list_to_compay_mertic(cm)
    return [cm.network_id] unless cm.algorithm_params
    algorithm_params = JSON.parse(cm[:algorithm_params])
    network_list = algorithm_params.values
    network_list << cm.network_id
  end

  def get_ui_level_names(cm)
    parent_id = CompanyMetric.where(analyze_company_metric_id: cm.id).first.try(:id)
    res = {}
    uilevels = UiLevelConfiguration.where(company_metric_id: parent_id)
    uilevels.each { |uil| res[uil.id] = uil[:name] }
    return res
  end

  def cds_get_network_relations_data(cid, pid, gid, sid)
    res = {}
    relevant_company_metrics = get_relevant_company_metrics(cid)
    snapshot = Snapshot.find(sid)
    count_employees = number_of_employees(cid, pid, gid)
    raise "No snapshots in system. can't calculate measure" if snapshot.nil?
    relevant_company_metrics.each_with_index do |specific_company_metric, index|
      al = Algorithm.find_by(id: specific_company_metric.algorithm_id)
      if al.nil?
        puts "Could not find algorithm with ID: #{specific_company_metric.algorithm_id}"
        next
      end
      algorithm_flow_ids = al.algorithm_flow_id
      network_id = specific_company_metric.network_id
      network_name = NetworkName.find(network_id).name
      next unless res.select { |_k, v| v[:name] == network_name }.empty?
      data = if count_employees > 500
               []
             else
               cds_get_data_to_relation(specific_company_metric, algorithm_flow_ids, sid, pid, gid)
             end
      res[index] = { relation: data, name: network_name, network_index: network_id, network_bundle: [network_id] } if !data.nil? && (!data.empty? || algorithm_flow_ids != EMAIL)
    end
    return res
  end

  def cds_get_group_measure_data(cid, gid, cm)
    algorithm_id = cm.algorithm_id
    result = { snapshots: {}, graph_data: { data: { values: [] } } }
    gid = Group.where(company_id: cid, parent_group_id: nil).pluck(:id) if gid.nil?
    subgroups = Group.where(parent_group_id: gid).pluck(:id)
    return nil if subgroups.empty?
    data = CdsMetricScore.where(algorithm_id: algorithm_id, company_id: cid, subgroup_id: subgroups.to_a).order('score DESC')
    return nil if data.map { |row| row[:score] }.max.zero?
    Snapshot.where(company_id: cid, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order(id: :asc).pluck(:id).each do |snapshot_id|
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
    result[:graph_data][:measure_name] = MetricName.find(cm.metric_id).name
    return result unless result[:snapshots].empty?
    return
  end

  def cds_get_network_dropdown_list_for_tab_for_questionnaire_only(cid)
    ret = []
    cms = CompanyMetric.where(algorithm_type_id: QUESTIONNAIRE_ONLY, company_id: cid)
    cms.each do |cm|
      ret << CompanyMetric.generate_metric_name_for_questionnaire_only(cm.network.name, cm.algorithm_id)
    end
    return ret
  end

  def cds_get_network_dropdown_list_for_tab(cid, tab)
    company_metrics_with_analyzed_company_metric_id = CompanyMetric.where("company_id = #{cid} AND analyze_company_metric_id IS NOT null").pluck(:id)
    query = "select ulc4.name, company_metric_id from ui_level_configurations as ulc4
             where company_id = #{cid} AND ulc4.level = 4 AND ulc4.parent_id IN
              (select id from ui_level_configurations as ulc3
               where ulc3.level = 3 AND ulc3.parent_id IN
               (select id from ui_level_configurations as ulc2
                where ulc2.level = 2 and ulc2.parent_id = #{tab.id}
              )
             ) and ulc4.company_metric_id in (#{company_metrics_with_analyzed_company_metric_id.join(',')})
             order by ulc4.name"
    res = []
    if company_metrics_with_analyzed_company_metric_id.any?
      ans = ActiveRecord::Base.connection.select_all(query)
      ans.map { |t| res.push(t['name']) }
    end
    return res
  end

  private

  def cds_get_data_to_relation(company_metric, algorithm_flow_id, sid, pid, gid)
    data = if algorithm_flow_id != EMAIL
             AlgorithmsHelper.calculate_pair_for_specific_relation_per_snapshot(sid, company_metric.network_id, pid, gid)
           else
             cds_calculate_pair_emails_per_snapshot(sid, pid, gid)
           end
    return data
  end

  def cds_calculate_pair_emails_per_snapshot(sid, pid, gid)
    emps_in_pin = CdsAdviseMeasureHelper.get_snapshot_node_list(sid, false, pid, gid)
    snapshot = Snapshot.find(sid)
    dt = snapshot.timestamp.to_i * 1000
    cds_create_edges_array_for_email_analyze(emps_in_pin, true, dt)
  end

  def cds_fetch_analyze_scores(cid, sid, pid, gid, company_metric_ids)
    pid = nil if pid == NO_PIN
    unless Company.find(cid).questionnaire_only?
      #gid = nil if gid == NO_GROUP || Group.find(gid).parent_group_id.nil?
    end
    other_emp_id = Employee.where(email: 'other@mail.com').first.try(:id)
    db_data = CdsMetricScore.where(company_id: cid, snapshot_id: sid, company_metric_id: company_metric_ids, pin_id: pid, group_id: gid).where.not(employee_id: other_emp_id)
    return db_data
  end

  def cds_empty_snapshots?(snapshots)
    snapshots.each do |_key, snapshot|
      return false if !snapshot.empty? && snapshot.map { |el| el[:measure] }.max.nonzero?
    end
    return true
  end

  def cds_flag_init_graph_data(metric_id, type='na')
    time = DateTime.parse(Time.now.to_s).strftime('%B %d, %Y')
    metric_name = get_metric_name(metric_id)
    return {
      measure_name: metric_name,
      last_updated: time,
      type: type
    }
  end

  def number_of_employees(cid, pid, gid)
    return Group.find(gid).try(:extract_employees).try(:count) if pid == NO_PIN && gid != NO_GROUP
    return EmployeesPin.where(pin_id: pid).try(:count, active: true) if pid != NO_PIN && gid == NO_GROUP
    return Employee.where(company_id: cid, active: true).try(:count)
  end

  def self.normalize(arr, max)
    if max.zero?
      arr.each do |o|
        o[:measure] = max.round(2)
      end
    else
      arr.each do |o|
        o[:measure] = (10 * o[:measure].to_f / max.to_f).round(2)
      end
    end
  end

  def cds_create_edges_array_for_email_analyze(emps, normalize = true, dt = nil)
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

  def get_relevant_company_metrics(cid)
    if Company.find(cid).questionnaire_only?
      return CompanyMetric.where(company_id: cid, algorithm_type_id: QUESTIONNAIRE_ONLY)
    else
      return CompanyMetric.where(company_id: cid, algorithm_type_id: ANALYZE)
    end
  end

  def filter_by_overlay_connections(data, oegid, oeid, sid)
    employee_ids = OverlaySnapshotData.pick_employees_by_group_and_snapshot(oegid, sid) unless oegid.nil?
    employee_ids = OverlaySnapshotData.pick_employees_by_id_and_snapshot(oeid, sid) unless oeid.nil?
    data.keys.each do |metric|
      data[metric.to_i][:degree_list] = data[metric.to_i][:degree_list].select { |obj| employee_ids.include? obj[:id] }
    end
    data
  end
end
