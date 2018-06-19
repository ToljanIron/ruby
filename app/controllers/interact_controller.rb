# frozen_string_literal: true
require 'oj'
require 'oj_mimic_json'

include SessionsHelper
include CdsUtilHelper

class InteractController < ApplicationController
  NO_GROUP ||= -1
  NO_PIN   ||= -1

  def get_question_data
    authorize :measure, :index?
    permitted = params.permit(:qid, :gid)

    qid = permitted[:qid]
    gid = permitted[:gid]
    cid = current_user.company_id
    qq = QuestionnaireQuestion.find(qid)
    quest = qq.questionnaire
    nid = qq.network_id
    sid = quest.snapshot_id
    gid = gid.nil? ? Group.get_root_group(cid) : gid
    cmid = CompanyMetric.where(network_id: nid, algorithm_id: 602).last.id

    res = CdsMetricScore
            .select("first_name || ' ' || last_name AS name, g.name AS group_name, cds_metric_scores.score")
            .from('cds_metric_scores')
            .joins('JOIN employees AS emps ON emps.id = cds_metric_scores.employee_id')
            .joins('JOIN groups AS g ON g.id = emps.group_id')
            .where(
              snapshot_id: sid,
              company_id: cid,
              company_metric_id: cmid,
              group_id: gid)
            .order("score DESC")

    res = Oj.dump(res)
    render json: res
  end

  ###############################################
  # Get everything needed to draw an explore map
  ###############################################
  def get_map
    authorize :measure, :index?
    permitted = params.permit(:qqid, :gid)

    qqid = permitted[:qqid].try(:to_i)
    gid = permitted[:gid].try(:to_i)
    cid = current_user.company_id

    qq = nil
    if qqid == -1
      qid = Questionnaire.last.id
      qq = QuestionnaireQuestion
             .where(questionnaire_id: qid)
             .order(:order)
             .last
      qqid = qq.id
    else
      qq = QuestionnaireQuestion.find(qqid)
    end

    quest = qq.questionnaire
    nid = qq.network_id
    sid = quest.snapshot_id
    gid = (gid.nil? || gid == 0) ? Group.get_root_group(cid) : gid
    cmid = CompanyMetric.where(network_id: nid, algorithm_id: 602).last.id

    groups = Group
      .select("groups.id AS gid, name, parent_group_id AS parentId, col.rgb AS color_name")
      .joins("JOIN colors AS col ON col.id = groups.color_id")
      .where(snapshot_id: sid)

    nodes = Employee
      .select("employees.id AS id, first_name || ' ' || last_name AS t, employees.group_id, g.name AS gname,
               cms.score AS d, rank_id, gender, ro.name AS role_name, o.name AS office_name,
               jt.name AS job_title_name")
      .joins("JOIN groups AS g ON g.id = employees.group_id")
      .joins("JOIN cds_metric_scores as cms ON cms.employee_id = employees.id")
      .joins("LEFT JOIN roles AS ro ON ro.id = employees.role_id")
      .joins("LEFT JOIN offices AS o ON o.id = employees.office_id")
      .joins("LEFT JOIN job_titles as jt ON jt.id = employees.job_title_id")
      .where("employees.company_id = #{cid} AND employees.snapshot_id = #{sid} AND cms.company_metric_id = #{cmid} AND cms.group_id = #{gid}")

    links = NetworkSnapshotData
      .select("from_employee_id AS id1, to_employee_id AS id2, value AS w")
      .where(company_id: cid, snapshot_id: sid, network_id: nid)
      .where("value > 0")


    res = {
      groups: groups,
      nodes: nodes,
      links: links,
      department: Group.find(gid).name,
      questionnaireName: quest.name,
      questionTitle: qq.title
    }

    res = Oj.dump(res)
    render json: res
  end
end
