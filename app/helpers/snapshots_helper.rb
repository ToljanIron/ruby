module SnapshotsHelper

	EMAILS_VOLUME_ALGORITHM_ID = 707

  def get_emails_volume_scores(interval_type, gids)
  	
  	# Contains score for month - last snapshot of each month - each snapshot is calculating measures 4 weeks back
  	scores_per_month = []
  	res = []
  	
  	interval_str = get_interval_type_string(interval_type)
		
    gids = gids.map(&:to_i) if !gids.nil?
    ############################################
    # Fix this to work with real groups
    gids = [1] if gids.nil? || gids.length === 0
    ############################################
    
		sqlstr = "SELECT *
							FROM (
						  SELECT 
						  	snapshots.id,
				 				#{interval_str},
							  timestamp,
							  score,
                group_id,  
			          max(timestamp) OVER (PARTITION BY month) AS max_timestamp
						  FROM snapshots 
              JOIN cds_metric_scores ON snapshots.id = cds_metric_scores.snapshot_id AND
              cds_metric_scores.group_id = ANY(ARRAY#{gids})
							) t
							WHERE timestamp = max_timestamp
							ORDER BY timestamp ASC
							LIMIT 20"

		sqlres = ActiveRecord::Base.connection.select_all(sqlstr)
  	
  	sqlres.each {|entry|
  		scores_per_month << {
  			'score'       => entry['score'],
  			'time_period' => entry["#{interval_str}"],
        'gid' => entry['group_id']
  		}
  	}

    ##################
    # Add here average on groups - reduce to single number and then continue with 
    # rest of average calculations 
    ##################


  	if(interval_type === 0)
  		res = scores_per_month
  	else
  		res = get_average_for_time_interval(scores_per_month)
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
  	if(interval_type === 0)
  		str = 'month'
  	elsif (interval_type === 1)
  		str = 'quarter'
		elsif (interval_type === 2)
			str = 'half_year'
		elsif (interval_type === 3)
			str = 'year'
  	end
  	return str
  end
end