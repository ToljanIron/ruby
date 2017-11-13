# frozen_string_literal: true
require 'oj'
require 'oj_mimic_json'

include SessionsHelper
include CdsUtilHelper
include ExternalDataHelper
include CalculateMeasureForCustomDataSystemHelper
include MeasuresHelper

class MeasuresController < ApplicationController
  MEASURE = 1
  FLAG    = 2
  ANALYZE = 3
  GROUP   = 4
  GAUGE   = 5

  NO_GROUP = -1
  NO_PIN   = -1

  def show
    authorize :measure, :index?
    companyid = current_user.company_id
    pinid = params[:pid].to_i
    groupid = params[:gid].to_i

    groupid = -1 if groupid.zero?

    groupid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?

    snapshot_type = params[:snapshot_type].to_i
    snapshot_type = 1 if snapshot_type.zero?
    measure_types = params[:measure_types]
    metrics = Metric.where(metric_type: 'measure')
    metrics = metrics.where(index: measure_types) unless measure_types.nil? || measure_types.empty? # TODO: move to db select into Metric.where at the line above
    cache_key = "measure-data-cid-#{companyid}-pid-#{pinid}-types-#{measure_types}-gid-#{groupid}-snapshottype-#{snapshot_type}"
    res = cache_read(cache_key)
    if res.nil?
      res = get_measure_data(companyid, pinid, metrics, groupid, snapshot_type) || {}
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  # def volume_of_emails
  #   include AlgorithmsHelper
  #   snapshot = Snapshot.where(company_id: params[:company_id].to_i).last.id
  #   volume = AlgorithmsHelper.volume_of_emails(snapshot, -1, -1) unless snapshot.nil?
  #   render json: volume
  # end

  def cds_show
    authorize :measure, :index?
    companyid = current_user.company_id
    pinid = params[:pid].to_i
    groupid = params[:gid].to_i

    groupid = -1 if groupid.zero?

    groupid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?

    snapshot_type = params[:snapshot_type].to_i
    snapshot_type = 1 if snapshot_type.zero?
    algorithms = Algorithm.where(algorithm_type_id: 1).pluck(:id)
    cache_key = "cds-measure-data-cid-#{companyid}-pid-#{pinid}-gid-#{groupid}-snapshottype-#{snapshot_type}"
    res = cache_read(cache_key)
    if res.nil?
      comp = Company.find(companyid)
      res = cds_get_measure_data(companyid, pinid, algorithms, groupid)     unless comp.questionnaire_only?
      res = cds_get_measure_data_for_questionnaire_only(companyid, groupid) if comp.questionnaire_only?

      res ||= {}
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  def show_flag
    authorize :measure, :index?
    companyid = current_user.company_id
    pinid = if !params[:pid].nil?
              params[:pid].to_i
            else
              NO_PIN
            end
    group_id = if !params[:gid].nil?
                 params[:gid].to_i
               else
                 NO_GROUP
               end

    groupid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?

    flag_types = params[:measure_types]
    snapshot_type = params[:snapshot_type].to_i
    snapshot_type = 1 if snapshot_type.zero?
    metrics = Metric.where(metric_type: 'flag')
    metrics.select! { |m| flag_types.include? m[:index] } unless flag_types.nil? || flag_types.empty?
    res = {}
    metrics.each do |flag_type|
      cache_key = "flag-data-#{companyid}-#{pinid}-#{group_id}-#{flag_type}"
      data = cache_read(cache_key)
      if data.nil?
        data = get_flag_data(companyid, pinid, group_id, flag_type[:index], snapshot_type)
        data = {} if data.nil?
      end
      cache_write(cache_key, data)
      res[flag_type[:index]] = data
    end
    render json: Oj.dump(res)
  end

  def cds_show_flag
    authorize :measure, :index?
    companyid = current_user.company_id
    pinid = if !params[:pid].nil?
              params[:pid].to_i
            else
              NO_PIN
            end
    group_id = if !params[:gid].nil?
                 params[:gid].to_i
               else
                 NO_GROUP
               end

    groupid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?

    company_metrics = CompanyMetric.where(company_id: companyid, algorithm_type_id: FLAG)
    res = {}
    company_metrics.each do |cm|
      cache_key = "cds-flag-data-#{companyid}-#{pinid}-#{group_id}-#{cm.id}"
      data = cache_read(cache_key)
      if data.nil?
        data = cds_get_flag_data(companyid, pinid, group_id, cm)
        data = {} if data.nil?
      end
      cache_write(cache_key, data)
      res[cm.id] = data
    end
    render json: Oj.dump(res)
  end

  def cds_network_dropdown_list
    authorize :measure, :index?
    cid = current_user.company_id
    res = {}
    if Company.find(cid).questionnaire_only?
      data = cds_get_network_dropdown_list_for_tab_for_questionnaire_only(cid)
      res['Collaboration'] = data
    else
      first_level_tabs = UiLevelConfiguration.where(company_id: cid, level: 1).order(:name)
      first_level_tabs.each do |tab|
        cache_key = "cds-network-dropdown-list-#{tab}"
        data = cache_read(cache_key)
        if data.nil?
          data = cds_get_network_dropdown_list_for_tab(cid, tab)
          data = {} if data.nil?
        end
        cache_write(cache_key, data)
        res[tab.name] = data unless data.empty?
      end
    end
    render json: Oj.dump(res)
  end

  def cds_show_gauge
    authorize :measure, :index?
    companyid = current_user.company_id
    pinid = if !params[:pid].nil?
              params[:pid].to_i
            else
              NO_PIN
            end

    group_id = if !params[:gid].nil?
                 params[:gid].to_i
               else
                 NO_GROUP
               end

    group_id = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?

    company_metrics = nil

    if !params[:type].nil? && params[:type] == 'level1'
      company_metrics = CompanyMetric.where(company_id: companyid)
                                     .where("algorithm_type_id in (#{AlgorithmType::GAUGE}, #{AlgorithmType::HIGHER_LEVEL})")
                                     .where('algorithm_id in (501, 502, 503, 504)')
      group_id = Group.get_parent_group(companyid).id
    else
      company_metrics = CompanyMetric.where(company_id: companyid)
                                     .where("algorithm_type_id in (#{AlgorithmType::GAUGE}, #{AlgorithmType::HIGHER_LEVEL})")
                                     .order(:id)
    end

    res = {}
    company_metrics.each do |cm|
      next if cm.algorithm.nil?
      cache_key = "cds-gauge-data-#{companyid}-#{pinid}-#{group_id}-#{cm.id}"
      data = cache_read(cache_key)
      if data.nil?
        data = cds_get_gauge_data(companyid, pinid, group_id, cm)
        data = {} if data.nil?
      end
      cache_write(cache_key, data)
      res[cm.id] = data
    end
    render json: Oj.dump(res)
  end

  def show_analyze
    authorize :measure, :index?
    cid = current_user.company_id
    pid = params[:pid].to_i
    sid = params[:sid].to_i
    gid = params[:gid].to_i
    gid = -1 if gid.zero?

    gid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?

    if params[:measure_type]
      index = params[:measure_type].to_i
      metrics = Metric.where(metric_type: 'analyze', index: index)
    else
      metrics = Metric.where(metric_type: 'analyze')
    end
    cache_key = "get_analyze_data-#{cid}-#{pid}-#{gid}-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      res = get_analyze_data(cid, pid, gid, metrics, sid)
      cache_write(cache_key, res)
    end
    cache_key = "show_analyze_network-#{cid}-#{pid}-#{gid}-#{sid}"
    networks = cache_read(cache_key)
    if networks.nil?
      networks = get_network_relations_data(cid, pid, gid, sid)
      cache_write(cache_key, networks)
    end
    render json: Oj.dump(measuers: res, networks: networks)
  end

  def cds_show_analyze
    authorize :measure, :index?
    cid = current_user.company_id
    pid = params[:pid].to_i
    sid = params[:sid].to_i
    gid = params[:gid].to_i
    oegid = params[:oegid].try(:to_i)
    oeid = params[:oeid].try(:to_i)
    gid = -1 if gid.zero?

    gid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?

    lgid = Group.find_group_in_snapshot(gid, sid)

    company_metrics = find_company_metrics(cid)

    cache_key = "cds_get_analyze_data-#{cid}-#{pid}-#{lgid}-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      res = if Company.find(cid).questionnaire_only?
              cds_get_analyze_data_questionnaire_only(cid, pid, lgid, company_metrics, sid)
            else
              cds_get_analyze_data(cid, pid, lgid, company_metrics, sid)
            end
      cache_write(cache_key, res)
    end
    cache_key = "cds_show_analyze_network-#{cid}-#{pid}-#{lgid}-#{sid}"
    networks = cache_read(cache_key)
    if networks.nil?
      networks = cds_get_network_relations_data(cid, pid, lgid, sid)
      cache_write(cache_key, networks)
    end
    res = filter_by_overlay_connections(res, oegid, oeid, sid) if oegid || oeid
    render json: Oj.dump(measuers: res, networks: networks)
  end

  def find_company_metrics(cid)
    if Company.find(cid).questionnaire_only?
      company_metrics = CompanyMetric.where(algorithm_type_id: 8, company_id: cid)
    else
      measure_comapny_metrics_ids_with_analyze = CompanyMetric.where(company_id: cid, algorithm_type_id: [MEASURE, FLAG, GAUGE]).where.not(analyze_company_metric_id: nil).pluck(:id)
      measure_comapny_metrics_ids_in_ui_level = measure_comapny_metrics_ids_with_analyze.select { |mid| !UiLevelConfiguration.find_by(company_metric_id: mid).nil? }
      analyze_comapny_metrics_ids = CompanyMetric.where(id: measure_comapny_metrics_ids_in_ui_level).pluck(:analyze_company_metric_id)
      company_metrics = CompanyMetric.where(id: analyze_comapny_metrics_ids)
      company_metrics = CompanyMetric.where(algorithm_type_id: 3) if ENV['RAILS_ENV'] == 'test'
    end
    return company_metrics
  end

  def cds_show_network_and_metric_names
    authorize :measure, :index?
    cid = current_user.company_id
    cache_key = "cds_network_and_metric_names-#{cid}"
    res = cache_read(cache_key)
    if res.nil?
      res = cds_get_network_and_metric_names(cid, ANALYZE)
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  def cds_show_flagged_employees
    authorize :measure, :index?
    cid = current_user.company_id
    sid = params[:sid].to_i
    gid = params[:gid].to_i
    gid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?
    company_metric_id = params[:company_metric_id].to_i
    res = cds_get_flagged_employees(cid, gid, company_metric_id, sid)
    render json: Oj.dump(flagged_employees: res)
  end

  def show_play_session
    authorize :measure, :index?
    cid = current_user.company_id
    pid = params[:pid].to_i
    gid = params[:gid].to_i
    gid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?
    network_id = params[:network_id].to_i
    measure_id = params[:measure_id].to_i
    cache_key = "show_play_session-#{cid}-#{pid}-#{gid}-#{network_id}-#{measure_id}"
    res = cache_read(cache_key)
    if res.nil?
      res = get_play_to_metric(cid, gid, pid, network_id, measure_id)
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  def show_group_measures
    authorize :measure, :index?
    cid = current_user.company_id
    gid = params[:gid].to_i
    gid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?
    gid = nil if gid.zero?
    res = []
    metrics = Metric.where(metric_type: 'group_measure')
    metrics.each do |metric|
      cache_key = "group_measure-data-#{cid}-#{gid}-#{metric.name}"
      data = cache_read(cache_key)
      if data.nil?
        data = get_group_measure_data(cid, gid, metric)
        cache_write(cache_key, data)
      end
      next if data.nil?
      res << data
    end
    render json: Oj.dump(res)
  end

  def cds_show_group_measures
    authorize :measure, :index?
    cid = current_user.company_id
    gid = params[:gid].to_i
    gid = GroupPolicy.get_max_allowed_group_id_for_user(groupid, current_user.group_id) if current_user.is_manager?
    gid = nil if gid.zero?
    res = []
    company_metrics = CompanyMetric.where(company_id: cid, algorithm_type_id: GROUP)
    company_metrics.each do |cm|
      metric_name = MetricName.find(cm.metric_id).name
      cache_key = "cds_group_measure-data-#{cid}-#{gid}-#{metric_name}"
      data = cache_read(cache_key)
      if data.nil?
        data = cds_get_group_measure_data(cid, gid, cm)
        cache_write(cache_key, data)
      end
      next if data.nil?
      res << data
    end
    render json: Oj.dump(res)
  end

  def get_employees_emails_scores
    puts "*******\nNeed to implement group level authorization !!!!!!\n*******\n"
    authorize :measure, :index?

    permitted = params.permit(:gids, :sid, :agg_method)

    cid = current_user.company_id
    gids = permitted[:gids].split(',')
    sid = permitted[:sid]
    agg_method = format_aggregation_method( permitted[:agg_method] )

    raise 'sid cant be empty' if sid == nil

    cache_key = "get_email_scores-#{cid}-#{gids}-#{sid}-#{agg_method}"
    res = cache_read(cache_key)
    if res.nil?
      top_scores = get_employees_emails_scores_from_helper(cid, gids, sid, agg_method)
      res = {
        top_scores: top_scores,
      }
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  def get_email_scores
    puts "*******\nNeed to implement group level authorization !!!!!!\n*******\n"
    authorize :measure, :index?

    permitted = params.permit(:gids, :currsid, :prevsid, :limit, :offset, :agg_method)

    cid = current_user.company_id
    gids = permitted[:gids].split(',')
    currsid = permitted[:currsid]
    prevsid = permitted[:prevsid]
    limit = permitted[:limit] || 10
    offset = permitted[:offset] || 0
    agg_method = format_aggregation_method( permitted[:agg_method] )

    raise 'currsid and prevsid can not be empty' if (currsid == nil)

    cache_key = "get_email_scores-#{cid}-#{gids}-#{currsid}-#{prevsid}-#{limit}-#{offset}-#{agg_method}"
    res = cache_read(cache_key)
    if res.nil?
      res = get_email_scores_from_helper(cid, gids, currsid, prevsid, limit, offset, agg_method)
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  def get_meetings_scores
    puts "*******\nNeed to implement group level authorization !!!!!!\n*******\n"
    authorize :measure, :index?

    permitted = params.permit(:gids, :currsid, :prevsid, :limit, :offset, :agg_method)

    cid = current_user.company_id
    gids = permitted[:gids].split(',')
    currsid = permitted[:currsid]
    prevsid = permitted[:prevsid]
    limit = permitted[:limit] || 10
    offset = permitted[:offset] || 0
    agg_method = format_aggregation_method( permitted[:agg_method] )

    raise 'currsid and prevsid can not be empty' if (currsid == nil )

    cache_key = "get_meetings_scores-#{cid}-#{gids}-#{currsid}-#{prevsid}-#{limit}-#{offset}-#{agg_method}"
    res = cache_read(cache_key)
    if res.nil?
      res = get_meetings_scores_from_helper(cid, gids, currsid, prevsid, limit, offset, agg_method)
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  def format_aggregation_method(agg_method)
    return 'group_id'     if (agg_method == 'groupName' || agg_method == 'Department')
    return 'office_id'    if (agg_method == 'officeName' || agg_method == 'Office')
    return 'algorithm_id' if (agg_method == 'algoName' || agg_method == 'Causes')
    raise "Unrecognized aggregation method: #{agg_method}"
  end

  def show_snapshot_list
    authorize :measure, :index?
    cid = current_user.company_id
    cache_key = "show_snapshot_list-#{cid}"
    res = cache_read(cache_key)
    if res.nil?
      res = get_snapshot_list(cid)
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end


  ## API for getting some statistics like:
  ##   - Total time spent in the entire company
  ##   - Averge time spent on emails by employees
  def get_email_stats
    authorize :snapshot, :index?
    params.permit(:sid, :gids)
    sid = params[:sid]
    gids = params[:gids].split(',')

    res = get_email_stats_from_helper(gids, sid)
    render json: Oj.dump(res)
  end

  def get_emails_time_picker_data
    authorize :snapshot, :index?

    params.permit(:sids, :gids, :interval_type)
    cid = current_user.company_id
    sids = params[:sids].split(',').map(&:to_i)
    gids = params[:gids].split(',')
    interval_type = params[:interval_type].to_i

    res = get_emails_volume_scores(cid, sids, gids, interval_type)
    res = Oj.dump(res)

    render json: res
  end

  def get_meetings_time_picker_data
    authorize :snapshot, :index?

    params.permit(:sids, :gids, :interval_type)
    cid = current_user.company_id
    sids = params[:sids].split(',').map(&:to_i)
    gids = params[:gids].split(',')
    interval_type = params[:interval_type].to_i

    res = get_time_spent_in_meetings(cid, sids, gids, interval_type)
    res = Oj.dump(res)

    render json: res
  end

  def get_dynamics_time_picker_data
    authorize :measure, :index?

    permitted = params.permit(:sids, :gids, :interval_type)
    cid = current_user.company_id
    sids = params[:sids].split(',').map(&:to_i)
    gids = permitted[:gids].split(',')
    interval_type = params[:interval_type].to_i

    res = get_group_densities(cid, sids, gids, interval_type)
    # res = {first: '1', second: '2'}

    render json: Oj.dump(res), status: 200
  end

  def get_dynamics_stats
    authorize :measure, :index?

    permitted = params.permit(:sids, :gids, :interval_type)

    cid = current_user.company_id
    sids = params[:sids].split(',').map(&:to_i)
    gids = permitted[:gids].split(',')
    interval_type = params[:interval_type].to_i

    res = get_dynamics_stats_from_helper(cid, sids, gids, interval_type)

    render json: Oj.dump(res), status: 200
  end

  def get_dynamics_scores
    authorize :measure, :index?

    permitted = params.permit(:interval_type, :sids, :gids, :aggregator_type)

    cid = current_user.company_id
    interval_type = params[:interval_type].to_i
    sids = params[:sids].split(',').map(&:to_i)
    gids = permitted[:gids].split(',')
    aggregator_type = permitted[:aggregator_type] # Aggregator from client. Use in the future - department/office

    res = get_dynamics_scores_from_helper(cid, sids, gids, interval_type, aggregator_type)

    render json: Oj.dump(res), status: 200
  end

  def get_dynamics_employee_scores
    authorize :measure, :index?

    permitted = params.permit(:interval_type, :sids, :gids)

    cid = current_user.company_id
    interval_type = params[:interval_type].to_i
    sids = params[:sids].split(',').map(&:to_i)
    gids = permitted[:gids].split(',')

    res = get_dynamics_employee_scores_from_helper(cid, sids, gids, interval_type)

    render json: Oj.dump(res), status: 200
  end

  def get_interfaces_time_picker_data
    authorize :measure, :index?

    permitted = params.permit(:sids, :gids, :interval_type)
    cid = current_user.company_id
    sids = params[:sids].split(',').map(&:to_i)
    gids = permitted[:gids].split(',')
    interval_type = params[:interval_type].to_i

    # FIX ME - this controller returns the same data as dynamics - this is just for mocking 
    # the time picker in the interfaces tab - Michael - 22.10.17
    res = get_group_densities(cid, sids, gids, interval_type)

    render json: Oj.dump(res), status: 200
  end

  def get_interfaces_scores
    authorize :measure, :index?

    permitted = params.permit(:interval_type, :sids, :gids, :aggregator_type)

    cid = current_user.company_id
    interval_type = params[:interval_type].to_i
    sids = params[:sids].split(',').map(&:to_i)
    gids = permitted[:gids].split(',')
    aggregator_type = permitted[:aggregator_type] # Aggregator from client. Use in the future - department/office

    res = get_interfaces_scores_from_helper(cid, sids, gids, interval_type, aggregator_type)

    render json: Oj.dump(res), status: 200
  end

  private

  def get_snapshot_list(cid)
    snapshot_list = Snapshot.where(company_id: cid, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order(timestamp: :desc)
    res = []
    snapshot_list.each_with_index do |snapshot|
      time = snapshot.timestamp.strftime('W-%V')+'  ' + week_start(snapshot.timestamp).gsub('.', '/') + ' - ' + week_end(snapshot.timestamp).gsub('.', '/')
      res.push(sid: snapshot.id, name: snapshot.name, time: time)
    end
    return res
  end

  def week_start(date)
    (date.beginning_of_week - 1).strftime('%d.%m.%y')
  end

  def week_end(date)
    (date.end_of_week - 1).strftime('%d.%m.%y')
  end

  def normalize_by_attribute(arr, attribute, factor)
    maximum = arr.map { |elem| elem["#{attribute}".to_sym] }.max
    return arr if maximum == 0
    arr.each do |o|
      o["#{attribute}".to_sym] = (factor * o["#{attribute}".to_sym] / maximum.to_f).round(2)
    end
  end
end
