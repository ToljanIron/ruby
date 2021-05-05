# frozen_string_literal: true
require 'oj'
require 'oj_mimic_json'

include SessionsHelper
include CdsUtilHelper

class InteractController < ApplicationController
  include InteractHelper

  NO_GROUP ||= -1
  NO_PIN   ||= -1

  def get_question_data
    authorize :interact, :view_reports?
    permitted = params.permit(:qqid, :gids)

    qqid = sanitize_id(permitted[:qqid]).try(:to_i)
    # gid = sanitize_id(permitted[:gid]).try(:to_i)
    gids = sanitize_ids(permitted[:gids])
    # raise 'Not authorized' if !current_user.group_authorized?(gids)
    gids = current_user.filter_authorized_groups(gids.split(','))
    Rails.logger.info "bbb"
    Rails.logger.info gids
    cid = current_user.company_id

    qq = nil
    qid = nil
    if qqid == -1
      qid = Questionnaire.last.id
      qq = QuestionnaireQuestion
             .where(questionnaire_id: qid)
             .where(active: true)
             .order(:order)
             .last
      qqid = qq.id
    else
      qq = QuestionnaireQuestion.find(qqid)
      qid = qq.questionnaire_id
    end
    questionnaire = Questionnaire.find(qid)
    Rails.logger.info "XXXXXXXXXXXXXXXXXXXXXXX"
    Rails.logger.info questionnaire.state
    Rails.logger.info "Questionnaire #{questionnaire.name} with id #{qid} IS COMPLETED? #{questionnaire.state == 'completed'}"
    if(questionnaire.state != 'completed')
      res = {
        indeg: [],
        question_scores: [],
        collaboration: 0,
        synergy: 0,
        centrality: 0
      }
    else
      quest = qq.questionnaire
      nid = qq.network_id
      sid = quest.snapshot_id
      # gid = (gid.nil? || gid == 0) ? Group.get_root_questionnaire_group(qid) : gid
      gids = (gids.nil? || gids.length == 0) ? [Group.get_root_questionnaire_group(qid)] : gids
      cmid = CompanyMetric.where(network_id: nid, algorithm_id: 601).last.id

      res_indeg = question_indegree_data(sid, gids, cid, cmid)
      res = {
        indeg: res_indeg,
        question_scores: question_scores_data(sid,gids,nid,cid),
        collaboration: question_collaboration_score(gids[0], nid),
        synergy: question_synergy_score(sid,gids,nid),
        centrality: question_centrality_score(sid,gids, nid)
      }
    end
    res = Oj.dump(res)
    render json: res
  end

  ###############################################
  # Get everything needed to draw an explore map
  ###############################################
  def get_map
    authorize :interact, :view_reports?
    permitted = params.permit(:qqid, :gids)

    qqid = sanitize_id(permitted[:qqid]).try(:to_i)
    gids = sanitize_gids(permitted[:gids])
    gids = current_user.filter_authorized_groups(gids.split(','))
    gids = gids.join(',')
    cid  = current_user.company_id

    qq = nil
    if qqid == -1
      qid = Questionnaire.last.id
      qq = QuestionnaireQuestion
             .where(questionnaire_id: qid)
             .where(active: true)
             .order(:order)
             .last
      qqid = qq.id
    else
      qq = QuestionnaireQuestion.find(qqid)
    end

    quest = qq.questionnaire
    nid = qq.network_id
    sid = quest.snapshot_id
    if (gids.nil? || gids == [] || gids == '')
      gids = Group
               .by_snapshot(sid)
               .where(questionnaire_id: quest.id)
               .pluck(:id).join(',')
    end

    cmid = CompanyMetric.where(network_id: nid, algorithm_id: 601).last.id

    groups = Group
      .select("groups.id AS gid, name, parent_group_id AS parentId, color_id")
      .where(snapshot_id: sid)
      .where("groups.id in (#{gids})")

    nodes = Employee
      .select("employees.id AS id, first_name || ' ' || last_name AS t, employees.group_id, g.name AS gname,
               cms.score AS d, rank_id, gender, ro.name AS role_name, o.name AS office_name,
               jt.name AS job_title_name, fa.name as param_a, g.color_id")
      .joins("JOIN groups AS g ON g.id = employees.group_id")
      .joins("JOIN cds_metric_scores as cms ON cms.employee_id = employees.id")
      .joins("LEFT JOIN roles AS ro ON ro.id = employees.role_id")
      .joins("LEFT JOIN offices AS o ON o.id = employees.office_id")
      .joins("LEFT JOIN job_titles as jt ON jt.id = employees.job_title_id")
      .joins("LEFT JOIN factor_as as fa ON fa.id = employees.factor_a_id")
      .where("employees.company_id = ? AND employees.snapshot_id = ? AND cms.company_metric_id = ?", cid, sid, cmid)
      .where("employees.group_id in (#{gids})" )

    eids = nodes.map { |n| n.id }

    links = NetworkSnapshotData
      .select("from_employee_id AS id1, to_employee_id AS id2, value AS w")
      .where(company_id: cid, snapshot_id: sid, network_id: nid)
      .where("value > 0")
      .where(from_employee_id: eids)
      .where(to_employee_id: eids)

    res = {
      groups: groups,
      nodes: nodes,
      links: links,
      department: nil,
      questionnaireName: quest.name,
      questionTitle: qq.title
    }

    res = Oj.dump(res)
    render json: res
  end
end
