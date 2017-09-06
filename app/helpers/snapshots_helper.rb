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

		sqlstr = "SELECT *
							FROM (
						  SELECT
						  	snapshots.id,
                algorithm_id,
				 				#{interval_str},
							  timestamp,
							  score,
                group_id,
			          max(timestamp) OVER (PARTITION BY month) AS max_timestamp
						  FROM snapshots
              JOIN cds_metric_scores ON snapshots.id = cds_metric_scores.snapshot_id AND
              snapshots.id = ANY(ARRAY#{sids}) AND
              cds_metric_scores.group_id = ANY(ARRAY#{gids})
							) t
							WHERE timestamp = max_timestamp AND algorithm_id = #{EMAILS_VOLUME_ALGORITHM_ID}
							ORDER BY timestamp ASC"

		sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

  	sqlres.each {|entry|
  		scores_per_month << {
  			'score'       => entry['score'],
  			'time_period' => entry["#{interval_str}"],
        'gid' => entry['group_id']
  		}
  	}

    res = get_average_for_time_interval(scores_per_month)
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

  def get_average_for_time_interval(data)
  	averages = []
  	values = []

  	data.each_with_index do |v, i|
  		values << v['score'].to_f

  		# If next element is from a different interval OR this is the last - calc the average
  		if((i < data.length - 1 && data[i]['time_period'] != data[i+1]['time_period']) || i === data.length - 1 )
  			averages << {time_period: data[i]['time_period'], score: (values.sum / values.size.to_f).round(2)}
				values = []
  		end
  	end
  	return averages
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
