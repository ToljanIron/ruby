module SnapshotsHelper

	EMAILS_VOLUME_ALGORITHM_ID = 707
  AVERAGE_TIME_SPENT_IN_MEETINGS_ALGORITHM_ID = 806

  # 74 - Bypassed managers, 100 - Isolated, 101 - Powerfull non-managers, 130 - Bottlenecks
  DYNAMICS_ALGORITHM_IDS = [74, 100, 101, 130]

  def get_emails_volume_scores(interval_type, current_gids, cid)
    
  	# Contains score for month - last snapshot of each month - each snapshot is calculating measures 4 weeks back
  	scores_per_month = []

  	res = []
  	gids = []

  	interval_str = get_interval_type_string(interval_type)
    
    sids = get_relevant_snapshot_ids(cid, 20)
    
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
      gids = gids.map(&:to_i)
    end

    sqlstr = "SELECT avg(score) as score, s.month, s.#{interval_str} as period 
              FROM cds_metric_scores
              JOIN snapshots AS s ON snapshot_id = s.id
              WHERE 
                snapshot_id IN (#{sids.join(',')}) AND
                group_id IN (#{gids.join(',')}) AND
                algorithm_id = #{EMAILS_VOLUME_ALGORITHM_ID}
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

  def get_time_spent_in_meetings(interval_type, current_gids, cid)
    # Contains score for month - last snapshot of each month - each snapshot is calculating measures 4 weeks back    
    scores_per_month = []

    res = []
    gids = []

    interval_str = get_interval_type_string(interval_type)
    
    sids = get_relevant_snapshot_ids(cid, 20)
    
    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
      gids = gids.map(&:to_i)
    end

    sqlstr = "SELECT avg(score) as score, s.month, s.#{interval_str} as period 
              FROM cds_metric_scores
              JOIN snapshots AS s ON snapshot_id = s.id
              WHERE
                snapshot_id IN (#{sids.join(',')}) AND
                group_id IN (#{gids.join(',')}) AND
                algorithm_id = #{AVERAGE_TIME_SPENT_IN_MEETINGS_ALGORITHM_ID}
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

  def get_dynamics_scores_from_helper(interval_type, current_gids, cid, sids)

    # Contains score for month - last snapshot of each month - each snapshot is calculating measures 4 weeks back
    scores_per_month = []
    
    res = []
    gids = []
    
    interval_str = get_interval_type_string(interval_type)

    if (current_gids.nil? || current_gids.length === 0)
      gids << Group.get_root_group(cid)
    else
      gids = get_relevant_group_ids(sids, current_gids)
      gids = gids.map(&:to_i)
    end

    sqlstr = "SELECT g.external_id AS group_name, algo.id AS algo_id, mn.name AS algo_name, 
                s.#{interval_str} AS period, avg(score) AS score
              FROM cds_metric_scores AS cds
              JOIN snapshots AS s ON snapshot_id = s.id
              JOIN groups AS g ON cds.group_id = g.id
              JOIN algorithms AS algo ON algo.id = cds.algorithm_id
              JOIN company_metrics AS cm ON cm.algorithm_id = cds.algorithm_id
              JOIN metric_names AS mn ON mn.id = cm.metric_id
              WHERE 
                cds.snapshot_id IN (#{sids.join(',')}) AND
                cds.group_id IN (#{gids.join(',')}) AND
                cds.algorithm_id IN (#{DYNAMICS_ALGORITHM_IDS.join(',')}) AND
                cds.company_id = #{cid}
              GROUP BY period, algo.id, mn.name, g.external_id
              ORDER BY g.external_id"

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

  def get_relevant_snapshots(cid, limit)
    sqlstr = "SELECT id AS sid, name, month, quarter, half_year, year
              FROM (
                SELECT
                snapshots.id,
                name,
                company_id,
                month,
                quarter,
                half_year,
                year,
                timestamp,
                max(timestamp) OVER (PARTITION BY month) AS max_timestamp
                FROM snapshots
                WHERE company_id = #{cid}
              ) t
              WHERE timestamp = max_timestamp AND company_id = #{cid}
              ORDER BY timestamp ASC
              LIMIT #{limit}"
    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)
    return sqlres
  end

  def get_relevant_snapshot_ids(cid, limit)
    return get_relevant_snapshots(cid, limit).pluck('sid')
  end

  def get_relevant_group_ids(sids, current_gids)
    res = []
    sids.each do |sid|
      grp = Group.find_groups_in_snapshot(current_gids, sid)
      res += grp
    end
    return res
  end

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
end
