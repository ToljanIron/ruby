
module CreateAlertsTaskHelper

  DIR_HIGH = 1
  DIR_LOW  = 2

  ALERT_TYPE_EXTREME_Z_SCORE_FOR_GAUGE   = 1
  ALERT_TYPE_EXTREME_Z_SCORE_FOR_MEASURE = 2

  def create_alerts(cid, sid, aid)
    snapshot = Snapshot.find_by(id: sid)
    raise "snapshot: #{sid} does not exist" if snapshot.nil?
    cm = CompanyMetric.where(company_id: cid, algorithm_id: aid).last
    raise "no company metric for algorithm with id: #{aid}" if cm.nil?
    al = Algorithm.find(aid)
    raise "no such algorithm: #{aid}" if al.nil?

    alerts = []
    case al.algorithm_type_id
    when 1
      alerts = create_alerts_for_extreme_z_score_measures(cid, sid, aid)
    when 5
      alerts = create_alerts_for_extreme_z_score_gauges(cid, sid, aid)
    else
      raise "Can not handle algorithm type: #{al.algorithm_type_id}"
    end

    alerts.each do |a|
      a.save!
    end
  end

  ####################### ALERT_TYPE_EXTREME_Z_SCORE_FOR_MEASURE ####################
  def create_alerts_for_extreme_z_score_measures(cid, sid, aid)
    ret = []
    gs = Group.by_snapshot(sid)
    gids = filter_groups_by_sizes(gs).pluck(:id)
    cm = CompanyMetric.where(company_id: cid, algorithm_id: aid).last

    high_res_id = extreme_z_score_measure_query(cid, sid, gids, aid, DIR_HIGH)
    ret << create_alert(cid, sid, high_res_id, nil, ALERT_TYPE_EXTREME_Z_SCORE_FOR_MEASURE, cm.id, DIR_HIGH) if !high_res_id.nil?

    low_res_id  = extreme_z_score_measure_query(cid, sid, gids, aid, DIR_LOW)
    ret << create_alert(cid, sid, low_res_id, nil, ALERT_TYPE_EXTREME_Z_SCORE_FOR_MEASURE, cm.id, DIR_LOW) if !low_res_id.nil?

    return ret
  end

  ###################################################################
  # In each group with more than 5 emps, which is not the root group
  # sum then number of employees with an extreme score (more than 2
  # standard deviations) and divide by group size. This way we see
  # which group has the highest proportion of extreme cases.
  ###################################################################
  def extreme_z_score_measure_query(cid, sid, gids, aid, direction)
    z_score_wherepart = 'z_score >= 2.0' if direction == DIR_HIGH
    z_score_wherepart = 'z_score <= -2.0' if direction == DIR_LOW
    dir = 'DESC' if direction == DIR_HIGH
    dir = 'ASC'  if direction == DIR_LOW

    sqlstr =
      "SELECT (
         SELECT COUNT(*)
         FROM cds_metric_scores AS cds
         JOIN employees AS emps ON emps.id = cds.employee_id
         JOIN groups AS ing ON ing.id = emps.group_id
         WHERE
           cds.company_id = #{cid} AND
           cds.snapshot_id = #{sid} AND
           algorithm_id = #{aid} AND
           #{z_score_wherepart} AND
           ing.nsleft >= outg.nsleft AND ing.nsright <= outg.nsright
         )::float / outg.hierarchy_size AS flag_proportion, outg.id AS outer_gid
       FROM groups AS outg
       WHERE
       outg.id IN (#{gids.join(',')}) AND
       outg.parent_group_id is not null AND
       outg.snapshot_id = #{sid}
       ORDER BY flag_proportion #{dir}
       LIMIT 1"
    res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    return nil if res.length == 0
    return nil if res[0]['flag_proportion'] == 0.0
    return res[0]['outer_gid']
  end

  ####################### ALERT_TYPE_EXTREME_Z_SCORE_FOR_GAUGE ######################
  def create_alerts_for_extreme_z_score_gauges(cid, sid, aid)
    ret = []
    gs = Group.by_snapshot(sid)
    gids = filter_groups_by_sizes(gs).pluck(:id)
    cm = CompanyMetric.where(company_id: cid, algorithm_id: aid).last

    high_res_id = extreme_z_score_gauges_query(cid, sid, gids, aid, DIR_HIGH)
    ret << create_alert(cid, sid, high_res_id, nil, ALERT_TYPE_EXTREME_Z_SCORE_FOR_GAUGE, cm.id, DIR_HIGH) if !high_res_id.nil?

    low_res_id  = extreme_z_score_gauges_query(cid, sid, gids, aid, DIR_LOW)
    ret << create_alert(cid, sid, low_res_id, nil, ALERT_TYPE_EXTREME_Z_SCORE_FOR_GAUGE, cm.id, DIR_LOW) if !low_res_id.nil?

    return ret
  end

  def extreme_z_score_gauges_query(cid, sid, gids, aid, direction)
    z_score_wherepart = 'z_score >= 2.0' if direction == DIR_HIGH
    z_score_wherepart = 'z_score <= -2.0' if direction == DIR_LOW
    dir = 'DESC' if direction == DIR_HIGH
    dir = 'ASC'  if direction == DIR_LOW

    return CdsMetricScore
      .select('g.id AS id')
      .joins('LEFT JOIN groups AS g ON g.id = cds_metric_scores.group_id')
      .where('cds_metric_scores.algorithm_id = ?', aid)
      .where('cds_metric_scores.snapshot_id = ?', sid)
      .where('cds_metric_scores.company_id = ?' ,cid)
      .where(z_score_wherepart)
      .where(group_id: gids)
      .order("z_score #{dir}")
      .limit(1)
      .pluck(:group_id)
      .last
  end
  ###################################################################################

  def create_alert(cid, sid, gid, eid, alert_type, cmid, direction)
      return Alert.new(
        company_id: cid,
        snapshot_id: sid,
        group_id: gid,
        employee_id: eid,
        alert_type: alert_type,
        company_metric_id: cmid,
        direction: direction,
      )
  end

  def filter_groups_by_sizes(groups)
    return groups.select do |group|
      group.size_of_hierarchy > min_group_size
    end
  end

  def min_group_size
    return 5
  end
end
