include SnapshotsHelper
require './app/helpers/calculate_measure_for_custom_data_system_helper.rb'

module MeasuresHelper

  CLOSENESS_AID = 200
  SYNERGY_AID = 201

  DYNAMICS_AIDS = [203, 205, 206, 207]
  DYNAMICS_AIDS_WITH_GROUPS = [204]

  INTERFACES_AIDS = [300, 310]

  EMAILS_VOLUME_AID = 707
  TIME_SPENT_IN_MEETINGS_AID = 806

  #########################################################################
  # Meetings date picker
  #########################################################################
  def get_time_spent_in_meetings(cid, sids, current_gids, interval_type)
    interval_str = Snapshot.field_from_interval_type(interval_type)

    # If empty gids - get the gid for the root - i.e. the company
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
    end

    group_extids = Group
        .select(:external_id)
        .where(id: [gids])
        .distinct
        .pluck(:external_id)
    groups_wherepart = "g.external_id IN ('#{group_extids.join('\',\'')}')"

    intervals = Snapshot
        .select("#{interval_str} as interval")
        .where(id: sids)
        .distinct
        .map { |s| s['interval'] }

    sqlstr = "SELECT (SUM(numerator) / SUM(denominator)) AS score_avg, s.#{interval_str} AS period
              FROM cds_metric_scores AS cds
              LEFT JOIN groups AS g ON g.id = cds.group_id
              JOIN snapshots AS s ON cds.snapshot_id = s.id
              WHERE
                s.#{interval_str} IN ('#{intervals.join('\',\'')}') AND
                #{groups_wherepart} AND
                cds.algorithm_id = #{TIME_SPENT_IN_MEETINGS_AID}
              GROUP BY period"
    sqlres = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    res = []
    sqlres.each do |entry|
      res << {
        'score'       => (entry['score_avg'].to_f / 60.0).round(2),
        'time_period' => entry['period']
      }
    end

    res = res.sort { |a,b| Snapshot.compare_periods(a['time_period'],b['time_period']) }
    return res
  end

  #######################################################################
  # Emails date picker
  #######################################################################
  def get_emails_volume_scores(cid, sids, current_gids, interval_type)
    res = []
    interval_str = Snapshot.field_from_interval_type(interval_type)

    # If empty gids - get the gid for the root - i.e. the company
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
    end

    group_extids = Group
        .select(:external_id)
        .where(id: [gids])
        .distinct
        .pluck(:external_id)
    groups_wherepart = "g.external_id IN ('#{group_extids.join('\',\'')}')"

    intervals = Snapshot
        .select("#{interval_str} as interval")
        .where(id: sids)
        .distinct
        .map { |s| s['interval'] }

    num_of_emps = Employee.where(group_id: current_gids).count

    sqlstr = "SELECT SUM(score) AS score_sum, s.#{interval_str} AS period
              FROM cds_metric_scores AS cds
              LEFT JOIN employees AS emps ON emps.id = cds.employee_id
              LEFT JOIN groups AS g ON g.id = emps.group_id
              JOIN snapshots AS s ON cds.snapshot_id = s.id
              WHERE
                s.#{interval_str} IN ('#{intervals.join('\',\'')}') AND
                #{groups_wherepart} AND
                cds.algorithm_id = #{EMAILS_VOLUME_AID}
              GROUP BY period"
    sqlres = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    sqlres.each do |r|
      r['score'] = r['score_sum'].to_f / num_of_emps
    end

    min = 0
    # If retreiving z-scores - they can be negative. Shift them up by the minimum
    #min_entry = sqlres.min {|a,b| a['score'] <=> b['score']} if !score
    #min = min_entry['score'] if !min_entry.nil?

    scale = CompanyConfigurationTable.incoming_email_to_time
    sqlres.each do |entry|
      score = entry['score'].to_f.round(2) + min.abs.to_f.round(2)
      score = score
      res << {
        'score'       => score  * scale,
        'time_period' => entry['period']
      }
    end

    res = res.sort { |a,b| Snapshot.compare_periods(a['time_period'],b['time_period']) }
    return res
  end

  ################################################################
  # Closeness level
  ################################################################
  def get_group_densities(cid, sids, current_gids, interval_type)
    res = []
    interval_str = Snapshot.field_from_interval_type(interval_type)

    # If empty gids - get the gid for the root - i.e. the company
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
    end
    group_extids =
      Group
        .select(:external_id)
        .where(id: [gids])
        .distinct
        .pluck(:external_id)

    intervals =
      Snapshot
        .select("#{interval_str} as interval")
        .where(id: sids)
        .distinct
        .map { |s| s['interval'] }

    num_of_emps = Employee.where(group_id: current_gids).count

    sqlstr = "SELECT AVG(score) AS score_avg, s.#{interval_str} AS period
              FROM cds_metric_scores AS cds
              JOIN groups AS g ON g.id = cds.group_id
              JOIN snapshots AS s ON cds.snapshot_id = s.id
              WHERE
                s.#{interval_str} IN ('#{intervals.join('\',\'')}') AND
                g.external_id IN ('#{group_extids.join('\',\'')}') AND
                cds.algorithm_id = #{CLOSENESS_AID}
              GROUP BY period"
    sqlres = ActiveRecord::Base.connection.select_all(sqlstr).to_hash

    sqlres.each do |r|
      r['score'] = r['score_avg'].to_f / num_of_emps
    end

    min = 0
    # If retreiving z-scores - they can be negative. Shift them up by the minimum
    #min_entry = sqlres.min {|a,b| a['score'] <=> b['score']} if !score
    #min = min_entry['score'] if !min_entry.nil?

    sqlres.each do |entry|
      score = entry['score'].to_f.round(2) + min.abs.to_f.round(2)
      score = score
      res << {
        'score'       => score,
        'time_period' => entry['period']
      }
    end

    res = res.sort { |a,b| Snapshot.compare_periods(a['time_period'],b['time_period']) }
    return res
  end


  def get_dynamics_stats_from_helper(cid, interval, gids, interval_type)
    res = {}
    res[:closeness] = get_dynamics_gauge_level(cid, interval, gids, interval_type, CLOSENESS_AID, 'closeness')
    res[:synergy]   = get_dynamics_gauge_level(cid, interval, gids, interval_type, SYNERGY_AID, 'synergy')

    return res
  end

  def get_dynamics_gauge_level(cid, interval, gids, interval_type, aid, algorithm_name)

    res = []

    interval_str = Snapshot.field_from_interval_type(interval_type)
    groupextids = Group.where(id: [gids]).pluck(:external_id)

    sqlstr =
      "SELECT g.english_name group_name, algo.id AS algo_id, mn.name AS algo_name,
          s.#{interval_str} AS period, AVG(z_score) AS avg_z_score
       FROM cds_metric_scores AS cds
       JOIN snapshots AS s ON snapshot_id = s.id
       JOIN groups AS g ON cds.group_id = g.id
       JOIN algorithms AS algo ON algo.id = cds.algorithm_id
       JOIN company_metrics AS cm ON cm.algorithm_id = cds.algorithm_id
       JOIN metric_names AS mn ON mn.id = cm.metric_id
       WHERE
         s.#{interval_str} = '#{interval}' AND
         g.external_id IN ('#{groupextids.join('\',\'')}') AND
         cds.algorithm_id= #{aid} AND
         cds.company_id = #{cid}
       GROUP BY period, algo.id, mn.name, group_name
       ORDER BY group_name"

    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

    sqlres.each do |entry|
      res << {
        'groupName'   => entry['group_name'],
        'algoName'    => entry['algo_name'],
        'aid'         => entry['algo_id'],
        'curScore' => entry['avg_z_score'].to_f.round(2),
        'time_period' => entry['period']
      }
    end

    count = res.length
    sum = 0
    res.each {|r| sum += r['curScore']}

    avg = (sum / count.to_f).round(2)

    return get_gauge_level(avg)
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

  def get_dynamics_scores_from_helper(cid, interval, gids, interval_type, agg_type)
    interval_str = Snapshot.field_from_interval_type(interval_type.to_i)

    groups_cond = '1 = 1'
    if gids != nil
      groupextids = Group.where(id: gids).pluck(:external_id)
      groups_cond = "g.external_id IN ('#{groupextids.join('\',\'')}')"
    end

    agg_type_select = nil
    agg_type_groupby = nil
    if agg_type == 'Department'
      agg_type_select = 'g.english_name AS group_name'
      agg_type_groupby = 'group_name'
    elsif agg_type == 'Offices'
      agg_type_select = 'off.name AS officename'
      agg_type_groupby = 'officename'
    end

    sqlstr =
      "(SELECT #{agg_type_select}, algo.id AS algo_id, mn.name AS algo_name,
         AVG(z_score) AS score, s.#{interval_str} AS period, g.external_id AS group_extid
      FROM cds_metric_scores AS cds
      JOIN snapshots AS s ON cds.snapshot_id = s.id
      JOIN employees AS emps ON emps.id = cds.employee_id
      JOIN groups AS g ON g.id = emps.group_id
      JOIN offices AS off ON off.id = emps.office_id
      JOIN algorithms AS algo ON algo.id = cds.algorithm_id
      JOIN company_metrics AS cm ON cm.algorithm_id = cds.algorithm_id
      JOIN metric_names AS mn ON mn.id = cm.metric_id
      WHERE
        s.#{interval_str} = '#{interval}' AND
        cds.algorithm_id IN (#{DYNAMICS_AIDS.join(',')}) AND
        #{groups_cond} AND
        cds.company_id = #{cid}
      GROUP BY #{agg_type_groupby}, algo_id, algo_name, period, g.external_id
      UNION
      SELECT #{agg_type_select}, algo.id AS algo_id, mn.name AS algo_name,
        AVG(z_score) AS score, s.#{interval_str} AS period, g.external_id AS group_extid
      FROM cds_metric_scores AS cds
      JOIN snapshots AS s ON cds.snapshot_id = s.id
      JOIN employees AS emps ON emps.id = cds.employee_id
      JOIN groups AS g ON g.id = cds.group_id
      JOIN offices AS off ON off.id = emps.office_id
      JOIN algorithms AS algo ON algo.id = cds.algorithm_id
      JOIN company_metrics AS cm ON cm.algorithm_id = cds.algorithm_id
      JOIN metric_names AS mn ON mn.id = cm.metric_id
      WHERE
        s.#{interval_str} = '#{interval}' AND
        cds.algorithm_id IN (#{DYNAMICS_AIDS_WITH_GROUPS.join(',')}) AND
        #{groups_cond} AND
        cds.company_id = #{cid}
      GROUP BY #{agg_type_groupby}, algo_id, algo_name, period, g.external_id)
      ORDER BY period"

    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

    sqlres = convert_group_external_ids_to_gids(sqlres, cid)
    a_min_max = find_min_max_values_per_algorithm(DYNAMICS_AIDS + DYNAMICS_AIDS_WITH_GROUPS, sqlres)
    ret = shift_and_append_min_max_values_from_array(a_min_max, sqlres)
    return ret
  end

  def get_dynamics_employee_scores_from_helper(cid, interval, gids, interval_type)
    puts "Looking for employees data"
    ret = get_employees_scores_by_aids(
            cid,
            gids,
            interval,
            interval_type,
            [206],
            'z_score',
            false)
    ret = convert_group_external_ids_to_gids(ret, cid)
    ret = convert_emp_emails_to_eids(ret, cid)

    ret.each do |r|
      name = r.delete('emp_name')
      r['name'] = name
      r['score'] = r['score'].to_f.round(2)
      r['aid'] = r.delete('metric_name')
    end
    return ret
  end

  def get_interfaces_scores_from_helper(cid, sids, current_gids, interval_type, aggregator_type)
    if(aggregator_type === 'Department')
      return get_interfaces_scores_for_departments(cid, sids, current_gids, interval_type)
    elsif (aggregator_type === 'Offices')
      return get_interfaces_scores_for_offices(cid, sids, interval_type)
    end
  end

  def get_interfaces_scores_for_departments(cid, sids, current_gids, interval_type)

    res = []
    groups = []

    interval_str = Snapshot.field_from_interval_type(interval_type)

    # If empty gids - get the gid for the root - i.e. the company
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      groups = get_relevant_groups(sids, current_gids)
      gids = groups.map{|g| g['id'].to_i}
    end

    # Interval larger than month - need to find latest sid - so we can display updated group names
    groups = get_groups_for_most_recent_snapshot(sids, groups) if interval_type != 1

    sqlstr = "SELECT g.external_id AS group_name, algo.id AS algo_id, mn.name AS algo_name,
                s.#{interval_str} AS period,
                CASE
                  when
                  SUM(denominator) = 0 then 0
                  else
                  (SUM(numerator)/SUM(denominator))
                  end AS score
              FROM cds_metric_scores AS cds
              JOIN snapshots AS s ON cds.snapshot_id = s.id
              JOIN groups AS g ON g.id = cds.group_id
              JOIN algorithms AS algo ON algo.id = cds.algorithm_id
              JOIN company_metrics AS cm ON cm.algorithm_id = cds.algorithm_id
              JOIN metric_names AS mn ON mn.id = cm.metric_id
              WHERE
                cds.snapshot_id IN (#{sids.join(',')}) AND
                cds.group_id IN (#{gids.join(',')}) AND
                cds.algorithm_id IN (#{INTERFACES_AIDS.join(',')}) AND
                cds.company_id = #{cid}
              GROUP BY group_name, algo_id, algo_name, period
              ORDER BY period"

    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

    a_min_max = find_min_max_values_per_algorithm(INTERFACES_AIDS, sqlres)
    a_min_max.each do |a|
      sqlres.each do |entry|
        next if a['aid'] != entry['algo_id']

        group = groups.find{|g| g['external_id'] === entry['group_name']}

        res << {
          'groupName'   => !group.nil? ? group['name'] : entry['group_name'],
          'algoName'    => entry['algo_name'],
          'aid'         => entry['algo_id'],
          'curScore'    => entry['score'].to_f.round(2),
          'time_period' => entry['period'],
          'min'         => a['min'].to_f.round(2),
          'max'         => a['max'].to_f.round(2)
        }
      end
    end
    return res
  end

  def get_interfaces_scores_for_offices(cid, sids, interval_type)
    res = []
    interval_str = Snapshot.field_from_interval_type(interval_type)

    sqlstr = "SELECT off.name AS officename, algo.id AS algo_id, mn.name AS algo_name,
                s.#{interval_str} AS period,
                CASE
                  when
                  SUM(denominator) = 0 then 0
                  else
                  (SUM(numerator)/SUM(denominator))
                  end AS score
              FROM cds_metric_scores AS cds
              JOIN snapshots as s ON s.id = cds.snapshot_id
              JOIN employees AS emps ON cds.employee_id = emps.id
              JOIN offices AS off ON off.id = emps.office_id
              JOIN algorithms AS algo ON algo.id = cds.algorithm_id
              JOIN company_metrics AS cm ON cm.algorithm_id = cds.algorithm_id
              JOIN metric_names AS mn ON mn.id = cm.metric_id
              WHERE
                cds.snapshot_id IN (#{sids.join(',')}) AND
                cds.algorithm_id IN (#{INTERFACES_AIDS.join(',')}) AND
                cds.company_id = #{cid}
              GROUP BY off.name, algo_id, algo_name, period
              ORDER BY period"

    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

    a_min_max = find_min_max_values_per_algorithm(INTERFACES_AIDS, sqlres)
    a_min_max.each do |a|
      sqlres.each do |entry|
        next if a['aid'] != entry['algo_id']

        res << {
          'officeName'   => entry['officename'],
          'algoName'    => entry['algo_name'],
          'aid'         => entry['algo_id'],
          'curScore'    => entry['score'].to_f.round(2),
          'time_period' => entry['period'],
          'min'         => a['min'].to_f.round(2),
          'max'         => a['max'].to_f.round(2)
        }
      end
    end
    return res
  end

  # Get integer representing level of gauge, from number 'z_score' - 0,1,2 corresponding to Low, Medium or High
  def get_gauge_level(z_score)
    level = -1
    if(z_score < -1)
      level = 0
    elsif (z_score > -1 && z_score < 1)
      level = 1
    else
      level = 2
    end
    return level
  end

  def get_relevant_groups(sids, current_gids)
    res = []
    sids.each do |sid|
      grp = Group.find_groups_in_snapshot(current_gids, sid)
      res += grp
    end
    return res
  end

  def get_relevant_group_ids(sids, current_gids)
    res = get_relevant_groups(sids, current_gids)
    return res.map{|r| r['id'].to_i}
  end

  def get_snapshots_by_period(cid, limit, interval_str, time_period)
    snapshots = get_last_snapshots_of_each_month(cid, limit)

    # If no time period is given - take the period of the last snapshot - by the interval.
    # If quarter is the interval type - the time period should be the quarter of the last snapshot
    time_period = snapshots.last[interval_str] if(time_period === '')

    # Select snapshots with the same time period
    res = snapshots.select{|s| s[interval_str] === time_period}

    # Get ids
    res = res.map {|r| r['sid']}
    return res
  end

  def get_groups_for_most_recent_snapshot(sids, groups)
    most_recent_snapshot = Snapshot.most_recent_snapshot(sids)
    return groups.select{|g| g['snapshot_id'] === most_recent_snapshot['id']}
  end

  def find_min_max_values_per_algorithm(aids, rows)
    # Find min/max for each algorithm - out of all groups for the same algorithm
    a_min_max = []
    aids.each do |aid|
      entries = rows.select{|s| s['algo_id']===aid}
      next if entries.nil? || entries.count === 0
      min = entries.min {|a,b| a['score'] <=> b['score']}['score']
      max = entries.max {|a,b| a['score'] <=> b['score']}['score']
      a_min_max << {
        'aid' => aid,
        'min' => min,
        'max' => max
      }
    end
    return a_min_max
  end

  # Parse query result -
  # Set the score. If the min is negative - shift all scores by the absolute of the min so scores
  # start from zero.
  def shift_and_append_min_max_values_from_array(a_min_max, rows)
    res = []
    invmode = CompanyConfigurationTable.is_investigation_mode?

    a_min_max.each do |a|
      rows.each do |entry|
        next if a['aid'] != entry['algo_id']

        min = a['min']
        max = a['max']
        score = entry['score']

        group_name =
          CalculateMeasureForCustomDataSystemHelper.create_group_name(
            entry['gid'],
            entry['group_name'],
            invmode)

        h = {
          'algoName'    => entry['algo_name'],
          'aid'         => entry['algo_id'],
          'time_period' => entry['period'],
          'original_score' => entry['score'],
          'groupName'   => group_name,
          'officeName'  => entry['officename'],
        }

        if(min < 0) # shift scores up if negative min
          h['min'] = 0
          h['max'] = (max + min.abs).to_f.round(2)
          h['curScore'] = (score + min.abs).to_f.round(2)
        else
          h['min'] = min.to_f.round(2)
          h['max'] = max.to_f.round(2)
          h['curScore'] = score.to_f.round(2)
        end

        res << h
      end
    end
    return res
  end
end
