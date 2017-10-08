module MeasuresHelper

  EMAIL_DENSITY_ALGORITHM_ID = 200

  def get_dynamics_stats_from_helper(cid, sids, current_gids, interval_type)
    
    res_arr = []

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
                cds.algorithm_id= #{EMAIL_DENSITY_ALGORITHM_ID} AND
                cds.company_id = #{cid}
              GROUP BY period, algo.id, mn.name, g.external_id
              ORDER BY g.external_id"

    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)

    sqlres.each do |entry|
      res_arr << {
        'groupName'   => entry['group_name'],
        'algoName'    => entry['algo_name'],
        'aid'         => entry['algo_id'],
        'avg_z_score' => entry['avg_z_score'].to_f.round(2),
        'time_period' => entry['period']
      }
    end

    count = res_arr.length
    sum = 0
    res_arr.each do |r|
      sum += r['avg_z_score']
    end

    avg = (sum / count.to_f).round(2)

    res = {closeness: get_gauge_level(avg)}

    # TO DO: 4.10.17 - average over scores and return LOW MEDIUM or HIGH for closeness
    # Same thing need to do with synergy algorithm in another function. Gather both results 
    # In the controller

    return res
  end

  def get_synergy_level_dynamics(cid, sids, current_gids, interval_type)







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
    elsif(z_score > 1)
      level = 2
    end
    return level
  end
end
