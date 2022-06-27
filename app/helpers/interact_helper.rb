module InteractHelper
  include AlgorithmsHelper

  def question_indegree_data(sid, gids, cid, cmid)
    cache_key = "question_indegree_data-sid#{sid}-gid#{gids}-cid#{cid}-cmid#{cmid}"
    res = cache_read(cache_key)
    return res if res

    # group = Group.find(gid)
    groups = Group.where(:id => gids, :snapshot_id => sid)
    return [] if groups.empty?
    gids_str = gids.join(',')
    # groups_conditions = '(1=2 '
    # groups.each do |g|
    #   groups_conditions += " OR (g.nsleft >= #{g.nsleft} AND g.nsright <= #{g.nsright})" 
    # end
    # groups_conditions += ") AND g.snapshot_id = #{sid}"
    # sql_str = "select * from groups g where #{groups_conditions}"
    # Rails.logger.info sql_str
    # group_ids = Group.find_by_sql(sql_str).pluck(:id)
    # Rails.logger.info group_ids
    
    # nsleft = group.nsleft
    # nsright = group.nsright

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
              company_metric_id: cmid)
            .where("g.id in (#{gids_str})") 
            .order("score DESC")
            # .where("g.nsleft >= ? AND g.nsright <= ? AND g.snapshot_id = ?", nsleft, nsright, sid)

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

  def question_scores_data(sid,gids, nid, cid,k_factor)
    res = QuestionnaireAlgorithm.get_question_score(sid,gids, nid, cid,k_factor)
    return res
  end

  def question_active_params(cid,sid)
    active_params = Employee.active_params(cid,sid)
    cfn = CompanyFactorName.where(company_id: cid,snapshot_id: sid).order(:id)
    param_names = {}
    cfn.each do |factor|
      if active_params.include?(factor.factor_name)
        param_names[factor.factor_name] = (factor.display_name ? factor.display_name : factor.factor_name)
      end
    end
    return param_names
  end

  def question_synergy_score(sid,gids, nid)
    # sid = Group.find(gid).snapshot_id
    res = AlgorithmsHelper.density_of_network2(sid, gids, nid)
    return res
  end

  def question_centrality_score(sid,gids, nid)
    # sid = Group.find(gid).snapshot_id
    res = AlgorithmsHelper.degree_centrality(gids, nid, sid)
    return res
  end

  def top_indegree_unconnected_nodes(links, nodes)
    linked_nodes = []
    nodes_ids = []
    unlinked_nodes = []
    links.map {|link| nodes_ids.push(link.id1,link.id2) }
    nodes = nodes.sort_by {|node| -node.d.to_i}
    nodes.each_with_index do |node, idx|
      if nodes_ids.include?(node.id)
        linked_nodes << node
      elsif idx < 10
        unlinked_nodes << node
      end
    end
    return linked_nodes + unlinked_nodes
  end
end
