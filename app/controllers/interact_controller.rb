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
    authorize :measure, :index?
    permitted = params.permit(:qqid, :gid)

    qqid = permitted[:qqid].try(:to_i)
    gid = permitted[:gid].try(:to_i)
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

    quest = qq.questionnaire
    nid = qq.network_id
    sid = quest.snapshot_id
    gid = gid.nil? ? Group.get_root_questionnaire_group(qid) : gid
    cmid = CompanyMetric.where(network_id: nid, algorithm_id: 602).last.id

    res_indeg = question_indegree_data(sid, gid, cid, cmid)

    res = {
      indeg: res_indeg,
      collaboration: question_collaboration_score(gid, nid),
      synergy: question_synergy_score(gid, nid),
      centrality: question_centrality_score(gid, nid)
    }
    res = Oj.dump(res)
    render json: res
  end

  ###############################################
  # Get everything needed to draw an explore map
  ###############################################
  def get_map
    authorize :measure, :index?
    permitted = params.permit(:qqid, :gids)

    qqid = permitted[:qqid].try(:to_i)
    gids = permitted[:gids]
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
      gids = Group.by_snapshot(sid).pluck(:id).join(',')
    end

    cmid = CompanyMetric.where(network_id: nid, algorithm_id: 602).last.id
   #  gidsStr = gids.join("','")

    groups = Group
      .select("groups.id AS gid, name, parent_group_id AS parentId, color_id")
      .where(snapshot_id: sid)
      .where("groups.id in (#{gids})")

    nodes = Employee
      .select("employees.id AS id, first_name || ' ' || last_name AS t, employees.group_id, g.name AS gname,
               cms.score AS d, rank_id, gender, ro.name AS role_name, o.name AS office_name,
               jt.name AS job_title_name, g.color_id")
      .joins("JOIN groups AS g ON g.id = employees.group_id")
      .joins("JOIN cds_metric_scores as cms ON cms.employee_id = employees.id")
      .joins("LEFT JOIN roles AS ro ON ro.id = employees.role_id")
      .joins("LEFT JOIN offices AS o ON o.id = employees.office_id")
      .joins("LEFT JOIN job_titles as jt ON jt.id = employees.job_title_id")
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
