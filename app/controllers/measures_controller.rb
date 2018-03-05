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

  ##################################################################
  # Generic cache for this controller. First generate a cache key
  #   from the params (sp), then look for it and add it to the cache
  #   if it doesn't exist.
  ##################################################################
  def measures_cache_result(api_name, sp)
    cache_key = sp.keys.inject(api_name) { |m, k| m = "#{m}-#{k}-#{sp[k]}" }
    res = cache_read(cache_key)
    if res.nil?
      res = yield
      cache_write(cache_key, res)
    end
    return res
  end

  ##################################
  # Same render patter in all calls
  ##################################
  def measures_return_result
    res = yield
    res = Oj.dump(res)
    render json: res
  end

  #########################################################
  # In most of the calls, pretty much the same params are
  # used, so handle them here.
  #########################################################
  def measures_params_sanitizer(pars)
    permitted = pars.permit(:gids, :curr_interval, :prev_interval, :limit, :offset, :agg_method, :interval_type, :sids, :segment_type)

    cid = current_user.company_id
    currsid = permitted[:curr_interval].sanitize_is_alphanumeric_with_slash   if !permitted[:curr_interval].nil?
    prevsid = permitted[:prev_interval].sanitize_is_alphanumeric_with_slash   if !permitted[:prev_interval].nil?
    agg_method = format_aggregation_method( permitted[:agg_method].sanitize_is_alphanumeric ) if !permitted[:agg_method].nil?
    interval_type = permitted[:interval_type].sanitize_is_string_with_space   if !permitted[:interval_type].nil?
    sids = params[:sids].split(',').map(&:to_i).map(&:sanitize_integer)       if !permitted[:sids].nil?
    gids = params[:gids].split(',').map(&:sanitize_integer)                   if !permitted[:gids].nil?
    gids = current_user.filter_authorized_groups(gids)

    return {
      cid: cid,
      sids: sids,
      gids: gids,
      interval_type: interval_type,
      currsid: currsid,
      prevsid: prevsid,
      limit: 10,
      offset: 0,
      agg_method: agg_method
    }
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

  def get_email_scores
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      raise 'currsid and prevsid can not be empty' if (sp[:currsid] == nil)
      measures_cache_result('get_email_scores', sp) do
        get_email_scores_from_helper(sp[:cid], sp[:gids], sp[:currsid], sp[:prevsid], sp[:limit], sp[:offset], sp[:agg_method], sp[:interval_type])
      end
    end
  end

  def get_employees_emails_scores
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      raise 'sid cant be empty' if sp[:currsid] == nil
      measures_cache_result('get_employees_emails_scores', sp) do
        top_scores = get_employees_emails_scores_from_helper(sp[:cid], sp[:gids], sp[:currsid], sp[:agg_method], sp[:interval_type])
        { top_scores: top_scores }
      end
    end
  end

  def get_employees_meetings_scores
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      raise 'sid cant be empty' if sp[:currsid] == nil
      measures_cache_result('get_employees_meetings_scores', sp) do
        top_scores = get_employees_meetings_scores_from_helper(sp[:cid], sp[:gids], sp[:currsid], sp[:agg_method], sp[:interval_type])
        { top_scores: top_scores }
      end
    end
  end

  def get_meetings_scores
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      raise 'currsid and prevsid can not be empty' if (sp[:currsid] == nil)
      measures_cache_result('get_meetings_scores', sp) do
        get_meetings_scores_from_helper(sp[:cid], sp[:gids], sp[:currsid], sp[:prevsid], sp[:limit], sp[:offset], sp[:agg_method], sp[:interval_type])
      end
    end
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
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_email_stats', sp) do
        get_email_stats_from_helper(sp[:gids], sp[:currsid], sp[:prevsid], sp[:interval_type])
      end
    end
  end

  def get_meetings_stats
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_meetings_stats', sp) do
        get_meetings_stats_from_helper(sp[:gids], sp[:currsid], sp[:prevsid], sp[:interval_type])
      end
    end
  end

  def get_emails_time_picker_data
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_emails_time_picker_data', sp) do
        get_emails_volume_scores(sp[:cid], sp[:sids], sp[:gids], sp[:interval_type])
      end
    end
  end

  def get_meetings_time_picker_data
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_meetings_time_picker', sp) do
        get_time_spent_in_meetings(sp[:cid], sp[:sids], sp[:gids], sp[:interval_type])
      end
    end
  end

  def get_dynamics_time_picker_data
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_dynamics_time_picker_data', sp) do
        get_group_densities(sp[:cid], sp[:sids], sp[:gids], sp[:interval_type])
      end
    end
  end

  def get_dynamics_stats
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_dynamics_stats', sp) do
        get_dynamics_stats_from_helper(sp[:cid], sp[:currsid], sp[:gids], sp[:interval_type])
      end
    end
  end

  def get_dynamics_scores
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_dynamics_scores', sp) do
        get_dynamics_scores_from_helper(sp[:cid], sp[:currsid], sp[:gids], sp[:interval_type], sp[:agg_method])
      end
    end
  end

  def get_dynamics_employee_scores
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_dynamics_employee_scores', sp) do
        get_dynamics_employee_scores_from_helper(sp[:cid], sp[:currsid], sp[:gids], sp[:interval_type])
      end
    end
  end

  def get_interfaces_stats
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_interfaces_stats', sp) do
        get_interfaces_stats_from_helper(sp[:cid], sp[:currsid], sp[:gids], sp[:interval_type])
      end
    end
  end

  def get_interfaces_time_picker_data
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_interfaces_time_picker_data', sp) do
        get_group_non_reciprocity(sp[:cid], sp[:sids], sp[:gids], sp[:interval_type])
      end
    end
  end

  def get_interfaces_scores
    authorize :measure, :index?
    measures_return_result do
      sp = measures_params_sanitizer(params)
      measures_cache_result('get_interfaces_scores', sp) do
        get_interfaces_scores_from_helper(sp[:cid], sp[:currsid], sp[:gids], sp[:interval_type], 'Department')
      end
    end
  end

  def format_aggregation_method(agg_method)
    return 'group_id'     if (agg_method == 'groupName' || agg_method == 'Department')
    return 'office_id'    if (agg_method == 'officeName' || agg_method == 'Offices')
    return 'algorithm_id' if (agg_method == 'algoName' || agg_method == 'Causes')
    raise "Unrecognized aggregation method: #{agg_method}"
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
