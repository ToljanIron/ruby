include SnapshotsHelper
module MeasuresHelper

  CLOSENESS_AID = 200
  SYNERGY_AID = 201

  # 74 - Bypassed managers, 100 - Isolated, 101 - Powerfull non-managers, 114 - internal champions 
    # 130 - Bottlenecks
  DYNAMICS_AIDS = [101, 114, 130]
  INTERFACES_AIDS = [709, 710]

  EMAILS_VOLUME_AID = 707
  TIME_SPENT_IN_MEETINGS_AID = 806

  def get_emails_volume_scores(cid, sids, current_gids, interval_type)
    return get_time_picker_data_by_aid(cid, sids, current_gids, interval_type, EMAILS_VOLUME_AID)
  end

  def get_time_spent_in_meetings(cid, sids, current_gids, interval_type)
    return get_time_picker_data_by_aid(cid, sids, current_gids, interval_type, TIME_SPENT_IN_MEETINGS_AID)
  end

  def get_group_densities(cid, sids, current_gids, interval_type)
    return get_time_picker_data_by_aid(cid, sids, current_gids, interval_type, CLOSENESS_AID, false)
  end

  def get_time_picker_data_by_aid(cid, sids, current_gids, interval_type, aid, score = true)

    res = []
    gids = []

    score_str = score ? 'score' : 'z_score' # Use score or z_score

    interval_str = get_interval_type_string(interval_type)
    
    # If empty gids - get the gid for the root - i.e. the company
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
      gids = gids.map(&:to_i)
    end

    sqlstr = "SELECT avg(#{score_str}) as score, s.month, s.#{interval_str} as period 
              FROM cds_metric_scores
              JOIN snapshots AS s ON snapshot_id = s.id
              WHERE
                snapshot_id IN (#{sids.join(',')}) AND
                group_id IN (#{gids.join(',')}) AND
                algorithm_id = #{aid}
              GROUP BY snapshot_id, s.month, s.timestamp, period
              ORDER BY s.timestamp ASC"
    
    # If query is for time period other than month - average over months. Wrap above query.
    if(interval_str != 'month')
      sqlstr = "SELECT avg(score) as score, period FROM (#{sqlstr}) t
                GROUP BY period
                ORDER BY period"
    end

    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

    sqlres.each do |entry|
      res << {
        'score'       => entry['score'].to_f.round(2),
        'time_period' => entry['period']
      }
    end
    
    return res
  end

  def get_dynamics_stats_from_helper(cid, sids, current_gids, interval_type)
    res = {}
    res[:closeness] = get_dynamics_gauge_level(cid, sids, current_gids, interval_type, CLOSENESS_AID, 'closeness')
    res[:synergy]   = get_dynamics_gauge_level(cid, sids, current_gids, interval_type, SYNERGY_AID, 'synergy')
    
    return res
  end

  def get_dynamics_gauge_level(cid, sids, current_gids, interval_type, aid, algorithm_name)
    
    res = []

    interval_str = get_interval_type_string(interval_type)

    # If empty gids - get the gid for the root - i.e. the company
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
      gids = gids.map(&:to_i)
    end

    sqlstr = "SELECT g.external_id AS group_name, algo.id AS algo_id, mn.name AS algo_name, 
                s.#{interval_str} AS period, avg(z_score) AS avg_z_score
              FROM cds_metric_scores AS cds
              JOIN snapshots AS s ON snapshot_id = s.id
              JOIN groups AS g ON cds.group_id = g.id
              JOIN algorithms AS algo ON algo.id = cds.algorithm_id
              JOIN company_metrics AS cm ON cm.algorithm_id = cds.algorithm_id
              JOIN metric_names AS mn ON mn.id = cm.metric_id
              WHERE
                cds.snapshot_id IN (#{sids.join(',')}) AND
                cds.group_id IN (#{gids.join(',')}) AND
                cds.algorithm_id= #{aid} AND
                cds.company_id = #{cid}
              GROUP BY period, algo.id, mn.name, g.external_id
              ORDER BY g.external_id"

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

  def get_dynamics_scores_from_helper(cid, sids, current_gids, interval_type, aggregator_type)
    if(aggregator_type === 'Department')
      return get_dynamics_scores_for_departments(cid, sids, current_gids, interval_type)
    elsif (aggregator_type === 'Offices')
      # Temporary - implement offices method
      return get_dynamics_scores_for_departments(cid, sids, current_gids, interval_type)
      # return get_collaboration_scores_for_offices(cid, sids, current_gids, interval_type)
    end
  end

  def get_dynamics_scores_for_departments(cid, sids, current_gids, interval_type)
    
    res = []
    gids = []
    
    interval_str = get_interval_type_string(interval_type)

    # If empty gids - get the gid for the root - i.e. the company
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
      gids = gids.map(&:to_i)
    end

    sqlstr = "SELECT g.external_id AS group_name, algo.id AS algo_id, mn.name AS algo_name, 
                    avg(z_score) as score, s.#{interval_str} AS period
              FROM cds_metric_scores AS cds
              JOIN snapshots AS s ON cds.snapshot_id = s.id
              JOIN groups AS g ON g.id = cds.group_id
              JOIN algorithms AS algo ON algo.id = cds.algorithm_id
              JOIN company_metrics AS cm ON cm.algorithm_id = cds.algorithm_id
              JOIN metric_names AS mn ON mn.id = cm.metric_id
              WHERE
                cds.snapshot_id IN (#{sids.join(',')}) AND
                cds.group_id IN (#{gids.join(',')}) AND
                cds.algorithm_id IN (#{DYNAMICS_AIDS.join(',')}) AND
                cds.company_id = #{cid}
              GROUP BY group_name, algo_id, algo_name, period
              ORDER BY period"

    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)
    
    sqlres.each do |entry|
      res << {
        'groupName'   => entry['group_name'],
        'algoName'    => entry['algo_name'],
        'aid'         => entry['algo_id'],
        'curScore'    => entry['score'].to_f.round(2),
        'time_period' => entry['period']
      }
    end
    return res
  end

  def get_interfaces_scores_from_helper(cid, sids, current_gids, interval_type, aggregator_type)
    if(aggregator_type === 'Department')
      return get_interfaces_scores_for_departments(cid, sids, current_gids, interval_type)
    elsif (aggregator_type === 'Offices')
      return get_interfaces_scores_for_offices(cid, sids, current_gids, interval_type)
    end
  end

  def get_interfaces_scores_for_departments(cid, sids, current_gids, interval_type)
    
    res = []
    gids = []
    
    interval_str = get_interval_type_string(interval_type)

    # If empty gids - get the gid for the root - i.e. the company
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
      gids = gids.map(&:to_i)
    end

    sqlstr = "SELECT g.external_id AS group_name, algo.id AS algo_id, mn.name AS algo_name, 
                    (SUM(numerator)/SUM(denominator)) as score, s.#{interval_str} AS period
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

    sqlres.each do |entry|
      res << {
        'groupName'   => entry['group_name'],
        'algoName'    => entry['algo_name'],
        'aid'         => entry['algo_id'],
        'curScore'    => entry['score'].to_f.round(2),
        'time_period' => entry['period']
      }
    end
    return res
  end

  def get_interfaces_scores_for_offices(cid, sids, current_gids, interval_type)
    
    res = []
    gids = []
    
    interval_str = get_interval_type_string(interval_type)

    sqlstr = "SELECT off.name AS officename, algo.id AS algo_id, mn.name AS algo_name,
              SUM(numerator) as numerator, SUM(denominator) as denominator,
              s.#{interval_str} AS period,
              CASE 
                when
                SUM(denominator) = 0 then -1000000
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
              GROUP BY s.id, off.name, algo_id, algo_name, period
              ORDER BY period"

    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

    sqlres.each do |entry|
      res << {
        'officeName'   => entry['officename'],
        'algoName'    => entry['algo_name'],
        'aid'         => entry['algo_id'],
        'curScore'    => entry['score'].to_f.round(2),
        'time_period' => entry['period']
      }
    end
    return res
  end

  # Get string representing the time interval type, from integer 'interval_type'
  def get_interval_type_string(interval_type)
    str = ''
    if(interval_type === 1)
      str = 'month'
    elsif (interval_type === 2)
      str = 'quarter'
    elsif (interval_type === 3)
      str = 'half_year'
    elsif (interval_type === 4)
      str = 'year'
    end
    return str
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

  # def get_relevant_snapshot_ids(cid, limit)
  #   return get_relevant_snapshots(cid, limit).pluck('sid')
  # end

  def get_relevant_group_ids(sids, current_gids)
    res = []
    sids.each do |sid|
      grp = Group.find_groups_in_snapshot(current_gids, sid)
      res += grp
    end
    return res
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
end

