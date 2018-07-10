module InteractHelper
  include AlgorithmsHelper

  def question_indegree_data(sid, gid, cid, cmid)
    cache_key = "question_indegree_data-sid#{sid}-gid#{gid}-cid#{cid}-cmid#{cmid}"
    res = cache_read(cache_key)
    return res if res

    res = CdsMetricScore
            .select("first_name || ' ' || last_name AS name, g.name AS group_name,
                     cds_metric_scores.score, c.rgb AS color")
            .from('cds_metric_scores')
            .joins('JOIN employees AS emps ON emps.id = cds_metric_scores.employee_id')
            .joins('JOIN groups AS g ON g.id = emps.group_id')
            .joins('JOIN colors AS c ON c.id = g.color_id')
            .where(
              snapshot_id: sid,
              company_id: cid,
              company_metric_id: cmid,
              group_id: gid)
            .order("score DESC")

    cache_write(cache_key, res)
    return res
  end

  ###################################################################
  # This query actually represents non-reciprocity.
  # In the query below, orig is wither person i sent to person j and
  #   rec is whether j reciprocated to i.
  ###################################################################
  def question_collaboration_score(gid, nid)
    sid = Group.find(gid).snapshot_id

    sqlstr = "
      SELECT AVG(rec / orig) AS score FROM (
        SELECT nsd1.value AS orig,
               COALESCE((SELECT value
                 FROM network_snapshot_data AS nsd2
                 WHERE
                   nsd2.from_employee_id = nsd1.to_employee_id AND
                   nsd2.to_employee_id = nsd1.from_employee_id AND
                   nsd2.network_id = #{nid} AND
                   nsd2.snapshot_id = #{sid}), 0) AS rec
                 FROM network_snapshot_data AS nsd1
                 WHERE
                   nsd1.network_id = #{nid} AND
                   nsd1.snapshot_id = #{sid} AND
                   nsd1.value = 1) AS innerquest"
    res = ActiveRecord::Base.connection.select_all(sqlstr)
    return res[0]['score'].to_f.round(2)
  end

  def question_synergy_score(gid, nid)
    sid = Group.find(gid).snapshot_id
    res = AlgorithmsHelper.density_of_network(sid, gid, -1, nid)
    return res[0][:measure]
  end

  def question_centrality_score(gid, nid)
    sid = Group.find(gid).snapshot_id
    res = AlgorithmsHelper.degree_centrality(gid, nid, sid)
    return res
  end
end
