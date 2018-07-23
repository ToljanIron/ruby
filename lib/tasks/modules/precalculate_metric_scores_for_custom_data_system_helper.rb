module PrecalculateMetricScoresForCustomDataSystemHelper
  require './app/helpers/algorithms_helper'
  require './app/helpers/interact_algorithms_helper'
  require './app/helpers/cds_util_helper'
  require 'logger'
  include AlgorithmsHelper
  include InteractAlgorithmsHelper
  include CdsUtilHelper

  NO_PIN = -1
  NO_GROUP = -1
  NO_SNAPSHOT = -1
  NO_COMPANY = -1

  INTERACT_ALGORITHM_ID_IN  = 601
  INTERACT_ALGORITHM_ID_OUT = 602
  INTERACT_ALGORITHM_TYPE   = 8


  def self.iterate_over_snapshots(cid, sid)
    sid = sid.to_i
    if sid != -1
      yield(cid, sid)
    else
      Snapshot.where(company_id: cid).each do |snapshot|
        yield(cid, snapshot.id)
      end
    end
  end

  def cds_calculate_scores(cid, gid = -1, pid = -1, aid = -1, sid = -1, rewrite = false)
    fail 'Ambiguous sub-group request with both pin-id and group-id' if gid != NO_GROUP && pid != NO_PIN
    algorithms = aid == -1 ? Algorithm.all.order(:id) : Algorithm.where(id: aid)
    fail 'No algorithms found!' if algorithms.empty?
    companies = cid == NO_COMPANY ? cds_find_companies(gid, pid, sid) : Company.where(id: cid)
    fail 'No company found!' if companies.empty?
    companies.each do |c|
      specific_company_metrics_rows = CompanyMetric.where(company_id: c.id, active: true).all
      fail 'No company metrics found!' if companies.empty?
      specific_company_metrics_rows.each do |company_metric_row|
        next unless algorithms.pluck(:id).include?(company_metric_row.algorithm_id)
        snapshots = sid == NO_SNAPSHOT ? Snapshot.where(company_id: c.id) : Snapshot.where(id: sid, company_id: c.id)
        fail 'No snapshots found!' if snapshots.empty?
        last_snapshot_id = Snapshot.where(company_id: c.id).order('id ASC').last.id
        snapshots.each do |s|
          next if (company_metric_row.algorithm_type_id == 2 && s.id != last_snapshot_id && !rewrite)
          cds_save_metric_for_structure(company_metric_row, s.id, gid, pid)
          snapshot = Snapshot.find(s.id)
          snapshot.update(status: :active)
        end
      end
    end
  end

  ## This function should only be used for the InterAct product, meaning that
  ## company_metrics do not count, only networks, and these networks should
  ## produce indegree/outdegree calcuations per each.
  def cds_calculate_scores_for_generic_networks(cid, sid, gid = -1)
    CdsMetricScore.where(snapshot_id: sid).delete_all
    puts "cid: #{cid}, sid: #{sid}, gid: #{gid}"

    qid = Questionnaire.where(snapshot_id: sid).try(:last).try(:id)
    fail "No questinnaire ID found for snapshot: #{sid}, aborting" if qid.nil?

    networks = NetworkName
                 .joins("JOIN questionnaire_questions as qq on qq.network_id = network_names.id")
                 .where(company_id: cid, questionnaire_id: qid)
                 .where("qq.active = true and qq.questionnaire_id = ?", qid)
    fail 'No networks found' if networks.empty?
    networks.each do |n|
      puts "Working on network: #{n.name}"
      nid = n.id

      cmin  = generate_company_metrics_for_network_in(cid, nid)
      cmout = generate_company_metrics_for_network_out(cid, nid)

      rgid = Group.get_root_questionnaire_group(qid)
      calculate_scores_for_a_generic_network(cid, sid, nid, rgid, cmin, cmout)
    end
  end

  def generate_company_metrics_for_network_in(cid, nid)
    cm = CompanyMetric.find_or_create_by!(
      company_id: cid,
      network_id: nid,
      metric_id:  -1,
      algorithm_id: INTERACT_ALGORITHM_ID_IN,
      algorithm_type_id: INTERACT_ALGORITHM_TYPE
    )
    return cm.id
  end

  def generate_company_metrics_for_network_out(cid, nid)
    cm = CompanyMetric.find_or_create_by!(
      company_id: cid,
      network_id: nid,
      metric_id:  -1,
      algorithm_id: INTERACT_ALGORITHM_ID_OUT,
      algorithm_type_id: INTERACT_ALGORITHM_TYPE
    )
    return cm.id
  end

  def calculate_scores_for_a_generic_network(cid, sid, nid, gid, cmin, cmout)
    ## Calculate the indegrees
    res = InteractAlgorithmsHelper.calculate_network_indegree(cid, sid, nid, gid)
    res.each do |r|
      eid   = r['employee_id'].to_i
      score = r['score'].to_i
      save_generic_socre(cid, sid, nid, gid, eid, cmin, INTERACT_ALGORITHM_ID_IN, score)
    end

    ## Calculate the outdegrees
    #res = InteractAlgorithmsHelper.calculate_network_outdegree(cid, sid, nid, gid)
    #res.each do |r|
      #eid   = r['employee_id'].to_i
      #score = r['score'].to_i
      #save_generic_socre(cid, sid, nid, gid, eid, cmout, INTERACT_ALGORITHM_ID_OUT, score)
    #end
  end

  def save_generic_socre(cid, sid, nid, gid, eid, cmid, aid, score)
    CdsMetricScore.create!(
      company_id: cid,
      employee_id: eid,
      pin_id: nil,
      group_id: gid,
      snapshot_id: sid,
      company_metric_id: cmid,
      score: score,
      algorithm_id: aid
    )
  end

  def cds_calculate_z_scores(cid, sid, rewrite = false, algo_type = 5)
    begin
      algorithms = CdsMetricScore.select(:algorithm_id)
                     .joins('JOIN algorithms as al ON al.id = algorithm_id JOIN algorithm_types as at ON al.algorithm_type_id = at.id')
                     .where(company_id: cid, snapshot_id: sid).where("at.id = #{algo_type}")
                     .distinct.pluck(:algorithm_id)
      algorithms.each do |aid|
        scores = CdsMetricScore
                   .select(:id, :group_id, :score, :z_score)
                   .where(company_id: cid, snapshot_id: sid, algorithm_id: aid)
                   .where('score > -1000000')
        puts "Working on: cid: #{cid}, sid: #{sid}, aid: #{aid}"
        next if scores.length == 0
        mean = array_mean(scores.pluck(:score))
        sd   = array_sd(scores.pluck(:score))
        scores.each do |s|
          z_score = sd != 0.0 ? ((s.score - mean) / sd).round(3) : 0.0
          if (s.z_score.nil? || rewrite)
            s.update(z_score: z_score)
          end
        end
      end
    rescue StandardError => e
      Rails.logger.error "Exception: #{e.message[0..1000]}"
      Rails.logger.error e.backtrace
      puts "EXCEPTION: #{e.message[0..1000]}"
      puts e.backtrace
      EventLog.log_event(event_type_name: 'ERROR', message: e.message)
    end
  end

  def cds_calculate_z_scores_for_gauges(cid, sid, rewrite = false)
    puts "In cds_calculate_z_scores for gauges cid: #{cid}, sid: #{sid}"
    cds_calculate_z_scores(cid, sid, rewrite, 5)
  end

  def cds_calculate_z_scores_for_measures(cid, sid, rewrite = false)
    puts "In cds_calculate_z_scores for measures cid: #{cid}, sid: #{sid}"
    cds_calculate_z_scores(cid, sid, rewrite, 1)
  end

  def find_flag_gauge_if_exists(s, cid, g, sid, hs)
    coordinted_z_score = hs['z_score'].to_f
    comparrable_gauge = Algorithm.find(s['algorithm_id'].to_i).comparrable_gauge_id
    if !comparrable_gauge.nil? && !CompanyMetric.where(company_id: cid, algorithm_id: comparrable_gauge).first.nil?
      company_m_id = CompanyMetric.where(company_id: cid, algorithm_id: comparrable_gauge).first
      coordinted_z_score = CdsMetricScore.where(company_id: cid, group_id: g.id, snapshot_id: sid, company_metric_id: company_m_id.id).first.z_score unless CdsMetricScore.where(company_id: cid, group_id: g.id, snapshot_id: sid, company_metric_id: company_m_id.id).first.nil?
    end
    coordinted_z_score
  end

  def recalculate_score_for_central_and_negative_algorithms(score, parent_skew_direction, son_skew_direction)
    parent_skew_direction ||= Algorithm::SCORE_SKEW_HIGH_IS_GOOD
    son_skew_direction    ||= Algorithm::SCORE_SKEW_HIGH_IS_GOOD
    parent_skew_direction = parent_skew_direction.to_i
    son_skew_direction    = son_skew_direction.to_i

    score *= (-1)                                           if parent_skew_direction == Algorithm::SCORE_SKEW_HIGH_IS_GOOD && son_skew_direction == Algorithm::SCORE_SKEW_HIGH_IS_BAD
    score *= (-1)                                           if parent_skew_direction == Algorithm::SCORE_SKEW_HIGH_IS_BAD  && son_skew_direction == Algorithm::SCORE_SKEW_HIGH_IS_GOOD
    score = ( 2 * Math::E**((-1) * (score**2))) - 1         if parent_skew_direction == Algorithm::SCORE_SKEW_HIGH_IS_GOOD && son_skew_direction == Algorithm::SCORE_SKEW_CENTRAL
    score = ((2 * Math::E**((-1) * (score**2))) - 1) * (-1) if parent_skew_direction == Algorithm::SCORE_SKEW_HIGH_IS_BAD  && son_skew_direction == Algorithm::SCORE_SKEW_CENTRAL
    score
  end

  def cds_calculate_l3_scores(cid, sid, rewrite = false)
    puts "In cds_calculate_l3_scores for sid: #{sid}"
    begin
      groups = Group.by_snapshot(sid)
      l3s = UiLevelConfiguration.where(company_id: cid, level: 3).where('company_metric_id is not null')
      l3s.each do |l3|
        l4_gauges = l3.find_l4_gauge_decendents
        l4_gauge_metric_ids = l4_gauges.pluck(:company_metric_id).join(',')

        l4_flag_metric_ids = l3.find_l4_hidden_flag_decendents

        groups.each do |g|
          aggregate_score = 0.0
          if (l4_gauges.count > 0 || l4_flag_metric_ids.count > 0)

            if (l4_gauges.count > 0)
              gauge_sql = "select cd.company_id, cd.group_id, snapshot_id, cd.company_metric_id, cd.algorithm_id as algorithm_id, ui.id as uid,cd.z_score, ui.weight
                        from cds_metric_scores as cd
                        join ui_level_configurations as ui on ui.company_metric_id = cd.company_metric_id
                        where cd.company_id = #{cid} and ui.company_id = #{cid} and
                          cd.company_metric_id in (#{l4_gauge_metric_ids}) and group_id = #{g.id} and snapshot_id = #{sid}"
            end

            if (l4_flag_metric_ids.count > 0)
              flags_sql = "select distinct cd.company_id, cd.group_id, snapshot_id, cd.company_metric_id, cd.algorithm_id as algorithm_id, ui.id as uid,cd.score as z_score, ui.weight
                      from cds_metric_scores as cd
                      join ui_level_configurations as ui on ui.company_metric_id = cd.company_metric_id
                      join algorithms as al on al.id = cd.algorithm_id
                      where cd.company_id = #{cid} and ui.company_id = #{cid} and
                        al.comparrable_gauge_id in (#{l4_flag_metric_ids.join(',')}) and group_id = #{g.id} and snapshot_id = #{sid}"
            end

            sqlstr = "#{gauge_sql} UNION #{flags_sql}" if !gauge_sql.nil? && !flags_sql.nil?
            sqlstr = gauge_sql                         if !gauge_sql.nil? && flags_sql.nil?
            sqlstr = flags_sql                         if gauge_sql.nil?  && !flags_sql.nil?

            if !sqlstr.nil?
              scores = ActiveRecord::Base.connection.select_all(sqlstr)

              parent_skew_direction = CompanyMetric.find(l3.company_metric_id).algorithm.meaningful_sqew_value
              scores.each { |s|
                hs = s.to_hash
                coordinted_z_score = hs['z_score'].to_f  ## find_flag_gauge_if_exists(s, cid, g, sid, hs)
                son_skew_direction = Algorithm.find(hs['algorithm_id']).meaningful_sqew_value
                coordinted_z_score = recalculate_score_for_central_and_negative_algorithms(coordinted_z_score, parent_skew_direction, son_skew_direction)
                aggregate_score += (hs['weight'].to_f * coordinted_z_score.to_f)
              }
            else
              aggregate_score = -1
            end
          end
          cm = CompanyMetric.find(l3.company_metric_id)
          next if cm.algorithm.nil?
          cds_metric_score = CdsMetricScore.find_or_create_by(
            company_id: cid,
            snapshot_id: sid,
            employee_id: -1,
            company_metric_id: cm.id,
            algorithm_id: cm.algorithm.id,
            group_id: g.id
          )
          cds_metric_score.update(score: aggregate_score.round(2))
        end
      end
    rescue StandardError => e
      Rails.logger.info "Exception: #{e.message[0..1000]}"
      Rails.logger.info e.backtrace
      puts "EXCEPTION: #{e.message[0..1000]}"
      puts e.backtrace
      EventLog.log_event(event_type_name: 'ERROR', message: e.message)
    end
  end

  def cds_calculate_l2_scores(cid, sid, rewrite = false)
    puts "In cds_calculate_l2_scores for sid: #{sid}"
    cds_calculate_higher_level_scores(cid, sid, 2, rewrite)
  end

  def cds_calculate_l1_scores(cid, sid, rewrite = false)
    puts "In cds_calculate_l1_scores for sid: #{sid}"
    cds_calculate_higher_level_scores(cid, sid, 1, rewrite)
  end

  def cds_calculate_higher_level_scores(cid, sid, level, rewrite = false)
    begin
      groups = Group.by_snapshot(sid)
      lhs = UiLevelConfiguration.where(company_id: cid, level: level).where('company_metric_id is not null')
      lhs.each do |lh|
        parent_skew_direction = CompanyMetric.find(lh.company_metric_id).algorithm.meaningful_sqew_value
        lls = lh.find_gauge_decendents
        ll_metric_ids = lls.pluck(:company_metric_id).join(',')
        groups.each do |g|
          aggregate_score = 0.0
          if lls.count > 0
            sqlstr = "select cd.score, ui.weight, al.meaningful_sqew, al.name
                      from cds_metric_scores as cd
                      join ui_level_configurations as ui on ui.company_metric_id = cd.company_metric_id
                      join algorithms as al on al.id = cd.algorithm_id
                      where cd.company_id = #{cid} and ui.company_id = #{cid} and
                        cd.company_metric_id in (#{ll_metric_ids}) and group_id = #{g.id} and snapshot_id = #{sid}"
            scores = ActiveRecord::Base.connection.select_all(sqlstr)
            scores.each { |s|
              hs = s.to_hash
              son_skew_direction = hs['meaningful_sqew']
              score = recalculate_score_for_central_and_negative_algorithms(hs['score'].to_f, parent_skew_direction, son_skew_direction)
              aggregate_score += (hs['weight'].to_f * score)
            }
          end
          cm = CompanyMetric.find(lh.company_metric_id)
          cds_metric_score = CdsMetricScore.find_or_create_by(
            company_id: cid,
            snapshot_id: sid,
            employee_id: -1,
            company_metric_id: cm.id,
            algorithm_id: cm.algorithm.id,
            group_id: g.id
          )
          cds_metric_score.update(score: aggregate_score.round(3))
        end
      end
    rescue StandardError => e
      Rails.logger.info "Exception: #{e.message[0..1000]}"
      Rails.logger.info e.backtrace
      puts "EXCEPTION: #{e.message[0..1000]}"
      puts e.backtrace
      EventLog.log_event(event_type_name: 'ERROR', message: e.message)
    end
  end

  def cds_find_companies(gid, pid, sid)
    if gid != NO_GROUP
      cid = Group.find(gid)[:company_id]
    elsif pid != NO_PIN
      cid = Pin.find(pid)[:company_id]
    elsif sid != NO_SNAPSHOT
      cid = Snapshot.find(sid)[:company_id]
    end
    return Company.where(id: cid) if cid
    return Company.all
  end

  def cds_save_metric_for_structure(company_metric_row, sid, gid, pid)
    values = []
    algorithm = Algorithm.find(company_metric_row.algorithm_id)
    if gid == NO_GROUP && pid == NO_PIN
      values += cds_calculate_with_no_group_and_no_pin(company_metric_row, sid)
    elsif gid != NO_GROUP
      fail 'No group found!' if Group.where(id: gid, company_id: company_metric_row.company_id).empty?
      CdsMetricScore.where(group_id: gid, snapshot_id: sid, company_metric_id: company_metric_row.id).delete_all
      values += cds_calculate_and_save_metric_scores(company_metric_row, sid, pid, gid, company_metric_row.algorithm_id)
    elsif pid != NO_PIN
      fail 'No pin found!' if Pin.where(id: pid, company_id: company_metric_row.company_id).empty?
      unless algorithm.algorithm_type_id == 1
        CdsMetricScore.where(pin_id: pid, snapshot_id: sid, company_metric_id: company_metric_row.id).delete_all
        pin_to_calculate = Pin.where(id: pid).first
        pin_to_calculate.update_attribute(:status, :in_progress)
        values += cds_calculate_and_save_metric_scores(company_metric_row, sid, pid, gid, company_metric_row.algorithm_id)
        pin_to_calculate.update_attribute(:status, :saved)
      end
    end
    return values
  end

  def cds_calculate_with_no_group_and_no_pin(company_metric_row, sid)
    values = []
    algorithm = Algorithm.find(company_metric_row.algorithm_id)
    CdsMetricScore.where(snapshot_id: sid, company_metric_id: company_metric_row.id).delete_all
    if algorithm.use_group_context || algorithm.algorithm_type_id != 1
      company_groups = Group.by_snapshot(sid)
      company_groups = put_mother_group_first(company_groups)
      company_groups.each do |group|
        puts "===> Working on group: #{group.id}"
        next if Group.find(group.id).extract_employees.empty? && !algorithm.algorithm_type_id != 1
        puts "Calculating !!"
        values += cds_calculate_and_save_metric_scores(company_metric_row, sid, NO_PIN, group.id, company_metric_row.algorithm_id)
      end
    else
      puts "Working without group context"
      cid = company_metric_row.company_id
      root_group_id = Group.get_root_group(cid, sid)
      values += cds_calculate_and_save_metric_scores(company_metric_row, sid, NO_PIN, root_group_id, company_metric_row.algorithm_id)
    end
    return values
  end

  def put_mother_group_first(company_groups)
    mother_group = nil
    company_groups.each do |group|
      mother_group = group if group.parent_group_id.nil?
    end
    new_groups = []
    unless mother_group.nil?
      new_groups.push(mother_group)
      company_groups.each do |group|
        new_groups.push(group) unless group.parent_group_id.nil?
      end
      company_groups = new_groups
    end
    return company_groups
  end

  def cds_calculate_and_save_metric_scores(company_metric_row, sid, pid, gid, algorithm_id)
    puts "Working on snapshot: #{sid}, group: #{gid}, algorithm: #{algorithm_id}"
    values = []
    begin
      cid = company_metric_row.company_id
      algo_params = company_metric_row.algorithm_params
      algorithm = Algorithm.find(company_metric_row.algorithm_id)
      network_b_id = JSON.parse(algo_params)['network_b_id'] if (algo_params && JSON.parse(algo_params))
      network_c_id = JSON.parse(algo_params)['network_c_id'] if (algo_params && JSON.parse(algo_params))
      lgid = Group.find_group_in_snapshot(gid, sid)
      args = {
        company_id: company_metric_row.company_id,
        network_b_id: network_b_id,
        network_c_id: network_c_id,
        snapshot_id: sid,
        network_id: company_metric_row.network_id,
        pid: pid,
        gid: lgid,
        algorithm_type: algorithm.algorithm_type_id
      }
      calculated = algorithm.run(args)
      pid = nil if pid == NO_PIN
      gid = nil if gid == NO_GROUP
      unless calculated.nil?
        calculated.each do |obj|
          row = []
          score = nil
          if obj[:measure].nil? && Algorithm.ifGauge(algorithm_id)
            score = nil
          else
            begin
              score = obj[:measure].to_f
            rescue => e
              puts 'ERROR: Measure field is null or undefined'
              message = e.message[0...1000]
              puts message
              puts e.backtrace.join("\n")
              raise "Error. Stopping..."
            end
            numerator = (obj[:numerator].to_f || nil)
            denominator = (obj[:denominator ].to_f || nil)
            param1 = (obj[:param1].to_f || nil)
            param2 = (obj[:param2].to_f || nil)
          end
          [cid, obj[:id].to_i, pid, lgid, sid, company_metric_row.id, score, numerator, denominator, param1, param2, algorithm_id, obj[:group_id]].each do |v|
            row.push(v || 'null')
          end
          values.push row
        end
      end

      entries_count = values.count

      (0..entries_count / 1000).each do |i|
        foffset = i * 1000
        toffset = (i == entries_count/1000 ? entries_count : ((i + 1) * 1000) - 1)
        puts "insert to cds_metric_scores, index: #{foffset}, entries_count: #{entries_count}"
        columns = %w(company_id employee_id pin_id group_id snapshot_id company_metric_id score numerator denominator param1 param2 algorithm_id subgroup_id)

        vals = values[foffset..toffset]
        query = "INSERT INTO cds_metric_scores (#{columns.join(', ')}) VALUES #{vals.map { |r| '(' + r.join(',') + ')' }.join(', ')}"
        query = query.gsub('NaN', '0')
        ActiveRecord::Base.connection.execute(query) if values.any?
      end
    rescue StandardError => e
      Rails.logger.info "Exception: #{e.message[0..1000]}"
      Rails.logger.info e.backtrace.join('\n')
      puts "EXCEPTION: #{e.message[0..1000]}"
      puts e.backtrace
      EventLog.log_event(event_type_name: 'ERROR', message: e.message)
      values = []
    ensure
      return values
    end
  end
end
