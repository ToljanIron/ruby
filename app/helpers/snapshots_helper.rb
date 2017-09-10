module SnapshotsHelper

	EMAILS_VOLUME_ALGORITHM_ID = 707

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
    
    # query is for time period other than month - average over months. Wrap above query.
    if(interval_str != 'month')
      sqlstr = "SELECT avg(score) as score, period FROM (#{sqlstr}) t
                GROUP BY period"
    end

		sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

    sqlres.each do |entry|
      res << {
        'score'       => entry['score'],
        'time_period' => entry["period"]
      }
    end
  	return res
  end

  def get_relevant_snapshot_ids(cid, limit)
    sqlstr = "SELECT id FROM (
              SELECT
              snapshots.id,
              company_id,
              month,
              timestamp,
              max(timestamp) OVER (PARTITION BY month) AS max_timestamp
              FROM snapshots
              WHERE company_id = #{cid}
              ) t
              WHERE timestamp = max_timestamp AND company_id = #{cid}
              ORDER BY timestamp ASC
              LIMIT #{limit}"
    sqlres = ActiveRecord::Base.connection.select_all(sqlstr).pluck('id')
    return sqlres
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
