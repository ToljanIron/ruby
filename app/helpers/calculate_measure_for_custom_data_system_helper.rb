# frozen_string_literal: true
require 'date'
require './app/helpers/algorithms_helper.rb'
# require './app/helpers/email_snapshot_data_helper.rb'
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

  EMAILS_VOLUME ||= 707


  def get_employees_emails_scores_from_helper(cid, gids, sid, agg_method)
    return get_employees_emails_scores_by_groups_and_offices(cid, gids, sid) if (agg_method == 'group_id' || agg_method == 'office_id')
    return get_employees_emails_scores_by_causes(cid, gids, sid) if (agg_method == 'algorithm_id')
  end

  def get_employees_emails_scores_by_groups_and_offices(cid, gids, sid)
    ret = CdsMetricScore
            .select("score, emps.first_name || ' ' || emps.last_name AS name, emps.img_url AS img_url, g.id AS gid, g.name AS group_name, o.name AS office_name, mn.name AS metric_name, emps.id AS eid")
            .from('cds_metric_scores AS cds')
            .joins('JOIN employees AS emps ON emps.id = cds.employee_id')
            .joins('JOIN groups AS g ON g.id = cds.group_id')
            .joins('JOIN offices AS o ON o.id = emps.office_id')
            .joins('JOIN company_metrics AS cms ON cms.id = cds.company_metric_id')
            .joins('JOIN metric_names AS mn ON mn.id = cms.metric_id')
            .where('cds.company_id = %s AND cds.snapshot_id = %s AND cds.group_id in (%s)', cid, sid, gids.join(','))
            .where("cds.algorithm_id IN (#{EMAILS_VOLUME})")
            .order('cds.score DESC')
            .limit(20)
    return ret
  end

  def get_employees_emails_scores_by_causes(cid, gids, sid)
    groups_condition = gids.length != 0 ? "g.id IN (#{gids.join(',')})" : '1 = 1'
    ret = CdsMetricScore
            .select("score, emps.first_name || ' ' || emps.last_name AS name, emps.img_url as img_url , g.id AS gid, g.name AS group_name, o.name AS office_name, mn.name AS metric_name, emps.id AS eid")
            .from('cds_metric_scores AS cds')
            .joins('JOIN employees AS emps ON emps.id = cds.employee_id')
            .joins('JOIN groups AS g ON g.id = cds.group_id')
            .joins('JOIN offices AS o ON o.id = emps.office_id')
            .joins('JOIN company_metrics AS cms ON cms.id = cds.company_metric_id')
            .joins('JOIN metric_names AS mn ON mn.id = cms.metric_id')
            .where('cds.company_id = %s AND cds.snapshot_id = %s', cid, sid)
            .where(groups_condition)
            .where("cds.algorithm_id IN (700, 701, 702, 703, 704, 705, 706, 707, 708)")
            .order('cds.score DESC')
            .limit(20)
    return ret
  end

  def get_avg_hours_per_employee(cid, gids, sid)
    root_group_id = Group.get_root_group(cid, sid)
    groups_condition = gids.length != 0 ? "g.id IN (#{gids.join(',')})" : '1 = 1'
    ret = CdsMetricScore
            .select(:score)
            .joins('JOIN employees AS emp ON cds_metric_scores.employee_id = emp.id')
            .joins('JOIN groups AS g ON g.id = emp.group_id')
            .where(group_id: root_group_id, snapshot_id: sid, algorithm_id: EMAILS_VOLUME)
            .where(groups_condition)
            .average(:score)
    return ret.round(1)
  end

  def get_meetings_scores_from_helper(cid, currgids, currsid, prevsid, limit, offset, agg_method)
    aids = [800, 801, 802, 803, 804, 805, 806]
    return get_scores_from_helper(cid, currgids, currsid, prevsid, aids, limit, offset, agg_method)
  end

  def get_email_scores_from_helper(cid, currgids, currsid, prevsid, limit, offset, agg_method)
    aids = [700, 701, 702, 703, 704, 705, 706, 707, 708]
    return get_scores_from_helper(cid, currgids, currsid, prevsid, aids, limit, offset, agg_method)
  end

  def get_scores_from_helper(cid, currgids, currsid, prevsid, aids, limit, offset, agg_method)
    currtopgids = calculate_group_top_scores(cid, currsid, currgids, aids)
    prevtopgids = prevsid.nil? ? nil : Group.find_groups_in_snapshot(currtopgids, prevsid)

    curr_group_wherepart = agg_method == 'group_id' ? "g.id IN (#{currtopgids.join(',')})" : '1 = 1'
    prev_group_wherepart = agg_method == 'group_id' && !prevsid.nil? ? "g.id IN (#{prevtopgids.join(',')})" : '1 = 1'
    algo_wherepart = agg_method == 'algorithm_id' ? "al.id IN (#{calculate_algo_top_scores(cid, currsid, currtopgids, aids).join(',')})" : '1 = 1'
    office_wherepart = agg_method == 'office_id' ? "emps.id IN (#{calculate_office_top_scores(cid, currsid, currtopgids, aids).join(',')})" : '1 = 1'

    curscores  = cds_aggregation_query(cid, currsid,  curr_group_wherepart, algo_wherepart, office_wherepart, aids)
    prevscores = prevsid.nil? ? nil : cds_aggregation_query(cid, prevsid, prev_group_wherepart, algo_wherepart, office_wherepart, aids)

    res = collect_cur_and_prev_results(curscores, prevscores)
    res = format_scores(res)
    return res
  end

  def format_scores(email_scores)
    res = []
    email_scores.each do |e|
      res << {
        gid: e['gid'],
        groupName: create_group_name(e),
        aid: e['algorithm_id'],
        algoName: e['algorithm_name'],
        officeName: e['office_name'],
        curScore: e['cursum'].to_f,
        prevScore: e['prevsum'].to_f
      }
    end
    return res
  end

  def create_group_name(e)
    invmode = CompanyConfigurationTable.is_investigation_mode?
    puts "invmode: #{invmode}"
    return e['group_name'] if !invmode
    return "#{e['gid']}_#{e['group_name']}" if invmode
  end

  def cds_aggregation_query(cid, sid, group_wherepart, algo_wherepart, office_wherepart, aids)
    sqlstr = "
      SELECT sum(cds.score), cds.group_id, g.name AS group_name, g.external_id AS group_extid, cds.algorithm_id, mn.name AS algorithm_name, emps.office_id, off.name AS office_name
      FROM cds_metric_scores AS cds
      JOIN groups AS g ON g.id = cds.group_id
      JOIN company_metrics AS cm ON cm.id = cds.company_metric_id
      JOIN algorithms AS al ON al.id = cm.algorithm_id
      INNER JOIN metric_names AS mn ON mn.id = cm.metric_id
      JOIN employees AS emps ON emps.id = cds.employee_id
      INNER JOIN offices AS off ON off.id = emps.office_id
      WHERE
        #{group_wherepart} AND
        #{algo_wherepart} AND
        #{office_wherepart} AND
        cds.snapshot_id = #{sid} AND
        cds.company_id = #{cid} AND
        cds.algorithm_id IN (#{aids.join(',')})
      GROUP BY cds.group_id, group_name, group_extid, cds.algorithm_id, algorithm_name, emps.office_id, office_name
      ORDER BY sum DESC"
    return ActiveRecord::Base.connection.select_all(sqlstr).to_hash
  end

  def collect_cur_and_prev_results(curscores, prevscores)
    res_hash = {}

    ## If there is no prevscores then copy over curscores
    prevscores ||= curscores

    curscores.each do |s|
      key = s
      cursum = key.delete('sum')
      gid = key.delete('group_id')          # Remove group_id and group_name from the key because they
      group_name = key.delete('group_name') # change every snapshot.
      res_hash[key] = [cursum, gid, group_name]
    end

    res_arr = []
    prevscores.each do |s|
      key = s
      entry = s.dup
      prevsum = key.delete('sum')
      key.delete('group_id')     # Remove group_id and group_name from the key because they
      key.delete('group_name')   # change every snapshot.
      entry['gid'] = res_hash[key][1]
      entry['group_name'] = res_hash[key][2]
      entry['cursum'] = res_hash[key][0].to_i
      entry['prevsum'] = prevsum.to_i
      res_arr << entry
    end

    return res_arr
  end

  def calculate_group_top_scores(cid, sid, gids, aids)
    sqlstr = "
      SELECT sum(score) AS sum, group_id
      FROM cds_metric_scores AS cds
      JOIN groups AS g ON g.id = cds.group_id
      where
        g.id IN (#{gids.join(',')}) AND
        cds.snapshot_id = #{sid} AND
        cds.company_id = #{cid} AND
        cds.algorithm_id IN (#{aids.join(',')})
      GROUP BY group_id
      ORDER BY sum DESC
      LIMIT 10"
    cds_scores = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    return cds_scores.map do |s|
      s['group_id']
    end
  end

  def calculate_algo_top_scores(cid, sid, gids, aids)
    sqlstr = "
      SELECT sum(score) AS sum, algorithm_id
      FROM cds_metric_scores AS cds
      JOIN groups AS g ON g.id = cds.group_id
      where
        g.id IN (#{gids.join(',')}) AND
        cds.snapshot_id = #{sid} AND
        cds.company_id = #{cid} AND
        cds.algorithm_id IN (#{aids.join(',')})
      GROUP BY algorithm_id
      ORDER BY sum DESC
      LIMIT 10"
    cds_scores = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    return cds_scores.map do |s|
      s['algorithm_id']
    end
  end

  def calculate_office_top_scores(cid, sid, gids, aids)
    sqlstr = "
      SELECT sum(score) AS sum, off.id AS office_id
      FROM cds_metric_scores AS cds
      JOIN employees AS emps ON emps.id = cds.employee_id
      JOIN offices AS off ON off.id = emps.office_id
      JOIN groups AS g ON g.id = cds.group_id
      WHERE
        g.id IN (#{gids.join(',')}) AND
        cds.snapshot_id = #{sid} AND
        cds.company_id = #{cid} AND
        cds.algorithm_id IN (#{aids.join(',')})
      GROUP BY off.id
      ORDER BY sum DESC
      LIMIT 10"
    cds_scores = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    office_ids = cds_scores.map do |s|
      s['office_id']
    end
    return Employee.where(office_id: office_ids).pluck(:id)
  end

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
        res[metric_name][:graph_data][:data][:values] << arrange_per_each_snapshot(sid, group_data)
      end
    end

    return res
  end

  def arrange_per_each_snapshot(snapshot_id, calculated_data)
    pin_avg = 0
    unless (calculated_data.nil? || calculated_data.empty?)
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
      last_updated: Time.now,
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

  def cds_get_network_dropdown_list_for_tab_for_questionnaire_only(cid)
    ret = []
    cms = CompanyMetric.where(algorithm_type_id: QUESTIONNAIRE_ONLY, company_id: cid)
    cms.each do |cm|
      ret << CompanyMetric.generate_metric_name_for_questionnaire_only(cm.network.name, cm.algorithm_id)
    end
    return ret
  end

  def cds_fetch_analyze_scores(cid, sid, pid, gid, company_metric_ids)
    pid = nil if pid == NO_PIN
    unless Company.find(cid).questionnaire_only?
      gid = nil if gid == NO_GROUP || Group.find(gid).parent_group_id.nil?
    end
    other_emp_id = Employee.where(email: 'other@mail.com').first.try(:id)
    db_data = CdsMetricScore.where(company_id: cid, snapshot_id: sid, company_metric_id: company_metric_ids, pin_id: pid, group_id: gid).where.not(employee_id: other_emp_id)
    return db_data
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

  def cds_empty_snapshots?(snapshots)
    snapshots.each do |_key, snapshot|
      return false if !snapshot.empty? && snapshot.map { |el| el[:measure] }.max.nonzero?
    end
    return true
  end

  def number_of_employees(cid, pid, gid, sid=nil)
    return Group.find(gid).try(:extract_employees).try(:count) if pid == NO_PIN && gid != NO_GROUP
    return EmployeesPin.where(pin_id: pid).try(:count) if pid != NO_PIN && gid == NO_GROUP
    return Employee.by_company(cid, sid).try(:count)
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

  def get_relevant_company_metrics(cid)
    if Company.find(cid).questionnaire_only?
      return CompanyMetric.where(company_id: cid, algorithm_type_id: QUESTIONNAIRE_ONLY)
    else
      return CompanyMetric.where(company_id: cid, algorithm_type_id: ANALYZE)
    end
  end
end
