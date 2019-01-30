# frozen_string_literal: true
require 'date'
require './app/helpers/algorithms_helper.rb'

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
  AVG_NUM_RECIPIENTS ||= 709
  MEETINGS_TIME_SPENT ||= 806
  MEETINGS_AVG_ATTENDEES ||= 805

  AGG_GROUP     ||= 'group_id'
  AGG_OFFICE    ||= 'office_id'
  AGG_ALGORITHM ||= 'algorithm_id'

  NA ||= -1000000

  def get_email_stats_from_helper(gids, curr_interval, prev_interval, interval_type)
    return [-1,-1,-1] if curr_interval.nil? || curr_interval == ''

    extgids = Group.where(id: [gids]).pluck(:external_id)
    groups_condition = gids.length != 0 ? "g.external_id IN ('#{extgids.join('\',\'')}')" : '1 = 1'

    ## get results for time spent
    total_time_spent, time_spent_avg, time_spent_diff =
       average_and_diff_of_scores(
         curr_interval,
         prev_interval,
         interval_type,
         groups_condition,
         EMAILS_VOLUME)

    ## get results for average number of emails
    num_emails_avg, num_emails_diff =
       average_and_diff_of_company_stat(
         curr_interval,
         prev_interval,
         interval_type,
         AVG_NUM_RECIPIENTS)

    scale = CompanyConfigurationTable.incoming_email_to_time

    time_spent_diff = 0 if !time_spent_diff.is_float?
    num_emails_diff = 0 if !num_emails_diff.is_float?

    return {
      total_time_spent: total_time_spent * scale,
      total_time_spent_diff: time_spent_diff,
      num_quantity_avg: num_emails_avg,
      num_quantity_diff: num_emails_diff
    }
  end

  def average_and_diff_of_company_stat(curr_interval, prev_interval, interval_type, aid)
    interval_str = Snapshot.field_from_interval_type(interval_type)
    currret = CdsMetricScore
            .select('AVG(score) AS avg')
            .joins('JOIN snapshots AS sn ON sn.id = cds_metric_scores.snapshot_id')
            .where(algorithm_id: aid)
            .where("sn.#{interval_str} = '#{curr_interval}'")

    if !prev_interval.nil?
      prevret = CdsMetricScore
            .select('AVG(score) AS avg')
            .joins('JOIN snapshots AS sn ON sn.id = cds_metric_scores.snapshot_id')
            .where(algorithm_id: aid)
            .where("sn.#{interval_str} = '#{prev_interval}'")
    end

    curravg = currret[0][:avg].to_f.round(2)

    if !prev_interval.nil?
      lastavg = prevret[0][:avg].to_f.round(2)
      diff = ((curravg - lastavg) / lastavg) * 100
    else
      diff = 0.0
    end

    return [curravg, diff.round(2)]
  end

  def average_and_diff_of_scores(curr_interval, prev_interval, interval_type, gids, aid)
    interval_str = Snapshot.field_from_interval_type(interval_type)
    currret = CdsMetricScore
            .select('AVG(score) AS avg, SUM(score) AS sum, COUNT(score) AS count')
            .joins('JOIN employees AS emp ON cds_metric_scores.employee_id = emp.id')
            .joins('JOIN groups AS g ON g.id = emp.group_id')
            .joins('JOIN snapshots AS sn ON sn.id = cds_metric_scores.snapshot_id')
            .where(algorithm_id: aid)
            .where("sn.#{interval_str} = '#{curr_interval}'")
            .where(gids)

    if !prev_interval.nil?
      prevret = CdsMetricScore
              .select('AVG(score) AS avg, SUM(score) AS sum')
              .joins('JOIN employees AS emp ON cds_metric_scores.employee_id = emp.id')
              .joins('JOIN groups AS g ON g.id = emp.group_id')
              .joins('JOIN snapshots AS sn ON sn.id = cds_metric_scores.snapshot_id')
              .where(algorithm_id: aid)
              .where("sn.#{interval_str} = '#{prev_interval}'")
              .where(gids)
    end

    avg = currret[0][:avg].to_f.round(2)
    currsum = currret[0][:sum].to_f

    if !prev_interval.nil?
      lastsum = prevret[0][:sum].to_f
      diff = ((currsum - lastsum) / lastsum) * 100
    else
      diff = 0.0
    end

    return [currsum, avg, diff.round(2)]
  end

  def get_employees_emails_scores_from_helper(cid, gids, interval, agg_method, interval_type)
    ret = nil
    if (agg_method == AGG_GROUP || agg_method == AGG_OFFICE)
      ret = get_employees_scores_by_aids(cid, gids, interval, interval_type, [707])
    end

    if (agg_method == AGG_ALGORITHM)
      ret = get_employees_scores_by_aids(cid, gids, interval, interval_type, [700, 701, 702, 703, 704, 705, 706])
    end

    ret = convert_group_external_ids_to_gids(ret, cid)
    ret = convert_emp_emails_to_eids(ret, cid)

    ret.each do |r|
      name = r.delete('emp_name')
      r['name'] = name
      r['score'] = r['score'].to_f.round(2)
    end
    return ret
  end

  def get_employees_meetings_scores_from_helper(cid, gids, interval, agg_method, interval_type)
    ret = nil
    if (agg_method == AGG_GROUP || agg_method == AGG_OFFICE)
      ret = get_employees_scores_by_aids(cid, gids, interval, interval_type, [807], 'score', false)
    end

    if (agg_method == AGG_ALGORITHM)
      ret = get_employees_scores_by_aids(cid, gids, interval, interval_type, [800, 801, 802, 803, 804], 'score', false)
    end

    ret = convert_group_external_ids_to_gids(ret, cid)
    ret = convert_emp_emails_to_eids(ret, cid)

    ret.each do |r|
      name = r.delete('emp_name')
      r['name'] = name
      r['score'] = (r['score'].to_f / 60.0).round(2)
    end
    return ret
  end

  def get_employees_scores_by_aids(cid, gids, interval, interval_type, aids, score_type = 'score', to_scale = true)
    currgextids = Group.where(id: [gids]).pluck(:external_id)
    groups_condition = currgextids.length != 0 ? "g.external_id IN ('#{currgextids.join('\',\'')}')" : '1 = 1'
    scale = to_scale ? CompanyConfigurationTable.incoming_email_to_time : 1
    snapshot_field = Snapshot.field_from_interval_type(interval_type)
    aids_str = aids.join(",")

    if CompanyConfigurationTable.is_investigation_mode?
      emp_name_field = 'emps.email'
      emp_groupby_field = 'emps.email'
      group_field = 'english_name'
    else
      emp_name_field = "emps.first_name || ' ' || emps.last_name"
      emp_groupby_field = "emps.first_name, emps.last_name, emps.email"
      group_field = 'name'
    end

    ## First, get top employees
    emps = CdsMetricScore
             .select("avg(#{score_type}) as avg, emps.email")
             .from('cds_metric_scores AS cds')
             .joins('JOIN snapshots AS sn ON sn.id = cds.snapshot_id')
             .joins('JOIN employees AS emps ON emps.id = cds.employee_id')
             .joins('JOIN groups AS g ON g.id = emps.group_id')
             .where("sn.#{snapshot_field} = \'#{interval}\' AND #{groups_condition}")
             .where("cds.algorithm_id IN (#{aids_str})")
             .group('emps.email')
             .order('avg DESC')
             .limit(100)

    emails = emps.map { |emp| emp['email'] }

    ## Then get their details
    ## SELECT (avg(#{score_type}) * #{scale}) AS score, emps.first_name || ' ' || emps.last_name AS emp_name,
    sqlstr = "
      SELECT (avg(#{score_type}) * #{scale}) AS score, emps.email, #{emp_name_field} AS emp_name,
             emps.img_url AS img_url, g.external_id AS group_extid, g.#{group_field} AS group_name, o.name AS office_name,
             mn.name AS metric_name, emps.email, jt.name AS job_title
      FROM cds_metric_scores AS cds
      JOIN employees AS emps ON emps.id = cds.employee_id
      JOIN groups AS g ON g.id = emps.group_id
      LEFT JOIN offices AS o ON o.id = emps.office_id
      LEFT JOIN job_titles AS jt ON jt.id = emps.job_title_id
      JOIN company_metrics AS cms ON cms.id = cds.company_metric_id
      JOIN metric_names AS mn ON mn.id = cms.metric_id
      JOIN snapshots AS sn ON sn.id = cds.snapshot_id
      WHERE
        emps.email IN ('#{emails.join("','")}') AND
        cds.algorithm_id IN (#{aids_str}) AND
        sn.#{snapshot_field} = \'#{interval}\'
      GROUP BY #{emp_groupby_field}, img_url, group_extid, g.#{group_field}, mn.name, office_name, job_title
      ORDER BY score DESC
      LIMIT 20"

    ret = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    return ret
  end

  def get_meetings_scores_from_helper(cid, currgids, currsid, prevsid, limit, offset, agg_method, interval_type)
    aids = [800, 801, 802, 804, 805, 807, 808]
    return get_scores_from_helper(cid, currgids, currsid, prevsid, aids, limit, offset, agg_method, interval_type, 'meetings')
  end

  def get_email_scores_from_helper(cid, currgids, currinter, previnter, limit, offset, agg_method, interval_type)
    aids = [707,700, 701, 702, 703, 704, 705, 706]
    ret = get_scores_from_helper(cid, currgids, currinter, previnter, aids, limit, offset, agg_method, interval_type, 'emails')
    return ret
  end

  def get_scores_from_helper(cid, currgids, currinter, previnter, aids, limit, offset, agg_method, interval_type, scale_type)
    currgextids = Group.where(id: [currgids]).pluck(:external_id)
    snapshot_field = Snapshot.field_from_interval_type(interval_type)
    currtopextgids = calculate_group_top_scores(cid, currinter, currgextids, [aids[0]], snapshot_field)

    curr_group_wherepart = agg_method == AGG_GROUP ? "outg.external_id IN ('#{currtopextgids.join('\',\'')}')" : '1 = 1'
    prev_group_wherepart = agg_method == AGG_GROUP && !previnter.nil? ? "outg.external_id IN ('#{currtopextgids.join('\',\'')}')" : '1 = 1'

    algo_wherepart = agg_method == AGG_ALGORITHM ? "al.id IN (#{calculate_algo_top_scores(cid, currinter, currtopextgids, aids, snapshot_field).join(',')})" : '1 = 1'
    office_wherepart = agg_method == AGG_OFFICE ? "emps.id IN (#{calculate_office_top_scores(cid, currinter, currtopextgids, aids, snapshot_field).join(',')})" : '1 = 1'

    currscores  = cds_aggregation_query(cid, currinter,  curr_group_wherepart, algo_wherepart, office_wherepart, aids, snapshot_field, currgextids)
    prevscores = previnter.nil? ? currscores : cds_aggregation_query(cid, previnter, prev_group_wherepart, algo_wherepart, office_wherepart, aids, snapshot_field, currgextids)

    currscores = convert_group_external_ids_to_gids(currscores, cid)
    prevscores = convert_group_external_ids_to_gids(prevscores, cid)

    res = collect_cur_and_prev_results(currscores, prevscores)
    res = format_scores(res, scale_type)
    return res
  end

  def convert_group_external_ids_to_gids(scores, cid)
    extids = scores.map { |s| s['group_extid'] }
    sid = Snapshot.last_snapshot_of_company(cid)
    groups = Group
               .select(:id, :external_id)
               .where(snapshot_id: sid)
               .where(external_id: extids)
    extidsmapping = {}
    groups.each do |g|
      extidsmapping[g[:external_id]] = g[:id]
    end

    scores.each do |s|
      s['gid'] = extidsmapping[s['group_extid']]
    end

    return scores
  end

  def convert_emp_emails_to_eids(scores, cid)
    emails = scores.map { |s| s['email'] }
    sid = Snapshot.last_snapshot_of_company(cid)
    emps = Employee
               .select(:id, :email)
               .where(snapshot_id: sid)
               .where(email: emails)
    emailsmapping = {}
    emps.each do |e|
      emailsmapping[e[:email]] = e[:id]
    end

    scores.each do |s|
      s['eid'] = emailsmapping[s['email']]
    end

    return scores
  end

  def format_scores(scores, scale_type)
    res = []
    scale = scale_type == 'emails' ? CompanyConfigurationTable.incoming_email_to_time : (1.0 / 60.0)
    invmode = CompanyConfigurationTable.is_investigation_mode?
    scores.each do |e|
      res << {
        gid: e['gid'],
        groupName: create_group_name(e['gid'], e['group_name'],invmode),
        groupSize: Group.num_of_emps(e['gid']),
        aid: e['algorithm_id'],
        algoName: e['algorithm_name'],
        officeName: e['office_name'],
        curScore: e['cursum'].to_f * scale,
        curNum: e['curnum'].to_i,
        prevScore: e['prevsum'].to_f * scale,
        prevNum: e['prevnum'].to_i
      }
    end
    return res
  end

  def create_group_name(gid, group_name, invmode)
    return group_name if !invmode
    return "#{gid}_#{group_name}" if invmode
  end

  def cds_aggregation_query(cid, interval, group_wherepart, algo_wherepart, office_wherepart, aids, snapshot_field, extids)
    group_name_field = CompanyConfigurationTable.is_investigation_mode? ? 'english_name' : 'name'
    sqlstr = "
      SELECT avg(outmost.inavg) AS group_hierarchy_avg, outmost.gextid AS group_extid,
             outmost.group_name, outmost.algorithm_id AS algorithm_id, outmost.algorithm_name
      FROM
        (SELECT
          (SELECT avg(incds.score)
           FROM groups as ing
           JOIN employees AS inemps ON inemps.group_id = ing.id
           JOIN cds_metric_scores AS incds ON incds.employee_id = inemps.id
           WHERE
             ing.nsleft >= outg.nsleft AND
             ing.nsright <= outg.nsright AND
             ing.snapshot_id = outg.snapshot_id AND
             ing.external_id IN ('#{extids.join('\',\'')}') AND
             inemps.snapshot_id = outg.snapshot_id AND
             incds.algorithm_id = outcds.algorithm_id ) AS inavg,
           outcds.snapshot_id AS sid, outg.external_id AS gextid, outg.#{group_name_field} AS group_name,
           outcds.algorithm_id AS algorithm_id, outmn.name AS algorithm_name
         FROM cds_metric_scores AS outcds
         JOIN employees AS outemps ON outemps.id = outcds.employee_id
         JOIN groups AS outg ON outg.id = outemps.group_id
         JOIN company_metrics AS outcm ON outcm.id = outcds.company_metric_id
         JOIN algorithms AS outal ON outal.id = outcm.algorithm_id
         INNER JOIN metric_names AS outmn ON outmn.id = outcm.metric_id
         JOIN snapshots AS outsn ON outsn.id = outcds.snapshot_id
         WHERE
           #{group_wherepart} AND
           #{algo_wherepart} AND
           outsn.#{snapshot_field} = '#{interval}' AND
           outcds.company_id = #{cid} AND
           outcds.score > #{NA} AND
           outcds.algorithm_id IN (#{aids.join(',')})
         GROUP BY outcds.snapshot_id, outg.external_id, outcds.algorithm_id, outg.nsleft, outg.nsright,
                  outg.snapshot_id, outg.#{group_name_field}, outmn.name
         ) AS outmost
      GROUP BY outmost.gextid, outmost.group_name, outmost.algorithm_id, outmost.algorithm_name
      ORDER BY group_hierarchy_avg DESC"

    ret = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    return ret
  end

  def collect_cur_and_prev_results(curscores, prevscores)
    res_hash = {}

    ## If there is no prevscores then copy over curscores
    prevscores ||= curscores

    curscores.each do |s|
      key = s
      cursum = key.delete('group_hierarchy_avg')
      curnum = key.delete('num')
      gid = key.delete('gid')          # Remove group_id and group_name from the key because they
      group_name = key.delete('group_name') # change every snapshot.
      res_hash[key] = [cursum, gid, group_name, curnum]
    end

    res_arr = []
    prevscores.each do |s|
      key = s
      entry = s.dup
      prevsum = key.delete('group_hierarchy_avg')
      prevnum = key.delete('num')
      key.delete('gid')     # Remove group_id and group_name from the key because they
      key.delete('group_name')   # change every snapshot.
      next if res_hash[key].nil?
      entry['gid'] = res_hash[key][1]
      entry['group_name'] = res_hash[key][2]
      entry['cursum'] = res_hash[key][0].to_f.round(2)
      entry['curnum'] = res_hash[key][3].to_i
      entry['prevsum'] = prevsum.to_f.round(2)
      entry['prevnum'] = prevnum.to_i
      res_arr << entry
    end

    return res_arr
  end

  def calculate_group_top_scores(cid, interval, gextids, aids, snapshot_field)
    sqlstr = "
      SELECT sum(score) AS sum, g.external_id AS group_external_id
      FROM cds_metric_scores AS cds
      JOIN employees AS emps ON emps.id = cds.employee_id
      JOIN groups AS g ON g.id = emps.group_id
      JOIN snapshots AS sn ON sn.id = cds.snapshot_id
      WHERE
        g.external_id IN ('#{gextids.join('\',\'')}') AND
        sn.#{snapshot_field} = '#{interval}' AND
        cds.company_id = #{cid} AND
        cds.algorithm_id IN (#{aids.join(',')})
      GROUP BY group_external_id
      ORDER BY sum DESC
      LIMIT 200"
    cds_scores = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    return cds_scores.map do |s|
      s['group_external_id']
    end
  end

  def calculate_algo_top_scores(cid, interval, gextids, aids, snapshot_field)
    sqlstr = "
      SELECT sum(score) AS sum, algorithm_id
      FROM cds_metric_scores AS cds
      JOIN employees AS emps ON emps.id = cds.employee_id
      JOIN groups AS g ON g.id = emps.group_id
      JOIN snapshots AS sn ON sn.id = cds.snapshot_id
      where
        g.external_id IN ('#{gextids.join('\',\'')}') AND
        sn.#{snapshot_field} = '#{interval}' AND
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

  def calculate_office_top_scores(cid, interval, gextids, aids, snapshot_field)
    sqlstr = "
      SELECT sum(score) AS sum, off.id AS office_id
      FROM cds_metric_scores AS cds
      JOIN employees AS emps ON emps.id = cds.employee_id
      JOIN offices AS off ON off.id = emps.office_id
      JOIN groups AS g ON g.id = emps.group_id
      JOIN snapshots AS sn ON sn.id = cds.snapshot_id
      WHERE
        g.external_id IN ('#{gextids.join('\',\'')}') AND
        sn.#{snapshot_field} = '#{interval}' AND
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

  ################################################################
  # Get two meetings related statistics:
  #   - Total time spent on meetings
  #   - Average number of participants
  ################################################################
  def get_meetings_stats_from_helper(gids, curr_interval, prev_interval, interval_type)
    return [-1,-1,-1] if curr_interval.nil? || curr_interval == ''

    cid = Group.find(gids.first).company_id
    interval_str = Snapshot.field_from_interval_type(interval_type)
    extgids = Group.where(id: [gids]).pluck(:external_id)

    ## get results for time spent in meetings
    time_spent_in_curr_interval = total_sum_from_gauge(cid, curr_interval, interval_str, extgids, MEETINGS_TIME_SPENT)
    time_spent_in_prev_interval = total_sum_from_gauge(cid, prev_interval, interval_str, extgids, MEETINGS_TIME_SPENT)
    time_spent_diff = time_spent_in_curr_interval - time_spent_in_prev_interval

    ## get results for average number of attendees in meetings
    avg_attendees_in_curr_interval = total_average_from_gauge(cid, curr_interval, interval_str, extgids, MEETINGS_AVG_ATTENDEES)
    avg_attendees_in_prev_interval = total_average_from_gauge(cid, prev_interval, interval_str, extgids, MEETINGS_AVG_ATTENDEES)
    avg_attendees_diff = avg_attendees_in_curr_interval - avg_attendees_in_prev_interval

    return {
      total_time_spent: time_spent_in_curr_interval / 60.0,
      total_time_spent_diff: (time_spent_diff / 60.0).round(2),
      num_quantity_avg: avg_attendees_in_curr_interval,
      num_quantity_diff: avg_attendees_diff
    }
  end

  private

  def total_sum_from_gauge(cid, interval, snapshot_field, extids, aid)
    ret = CdsMetricScore
      .select('SUM(cds.numerator) AS sum')
      .from('cds_metric_scores AS cds')
      .joins('JOIN groups AS g ON g.id =  cds.group_id')
      .joins('JOIN snapshots AS sn ON sn.id = cds.snapshot_id')
      .where(["sn.%s = '%s'", snapshot_field, interval])
      .where(["cds.company_id = ?", cid])
      .where(["cds.score > #{NA}"])
      .where("g.external_id IN ('#{extids.join("','")}')")
      .where(["cds.algorithm_id = ?", aid])

    return ret[0]['sum'].to_f.round(2)
  end

  def total_average_from_gauge(cid, interval, snapshot_field, extids, aid)
    sqlstr = "
      SELECT AVG(agg) FROM
       (SELECT (SUM(cds.numerator) / SUM(cds.denominator)) AS agg, cds.snapshot_id AS snid
        FROM cds_metric_scores AS cds
        JOIN groups AS g ON g.id =  cds.group_id
        JOIN snapshots AS sn ON sn.id = cds.snapshot_id
        WHERE
          sn.#{snapshot_field} = '#{interval}' AND
          cds.company_id = #{cid} AND
          cds.score > #{NA} AND
          g.external_id IN ('#{extids.join('\',\'')}') AND
          cds.algorithm_id = #{aid}
        GROUP BY snid) inneragg"

    ret = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    return ret[0]['avg'].to_f.round(2)
  end

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
