require 'oj'
require 'oj_mimic_json'

include SessionsHelper
include CdsGroupsHelper
include CdsUtilHelper

class GroupsController < ApplicationController
  def groups
    authorize :group, :index?

    cid = current_user.company_id
    sid = sanitize_id(params[:sid]).to_i
    sid = sid == 0 ? Snapshot.last_snapshot_of_company(cid) : sid
    qid = sanitize_id(params[:qid])

    cache_key = "groups-comapny_id-uid-#{current_user.id}-cid-#{cid}-sid-#{sid}-qid-#{qid}"
    res = cache_read(cache_key)
    if res.nil?
      puts 'Retrieving all groups. Replace with authorized groups only'
      groups_ids = Group.by_snapshot(sid).pluck(:id) if qid.nil?
      groups_ids = Group.by_snapshot(sid).where(questionnaire_id: qid.to_i).pluck(:id) if !qid.nil?
      groups_ids = current_user.filter_authorized_groups(groups_ids)

      raise 'empty groups select list' if groups_ids.nil? || groups_ids.length == 0
      res = CdsGroupsHelper.groups_with_sizes(groups_ids)
      cache_write(cache_key, res)
    end
    res = { groups: res }
    render json: Oj.dump(res), status: 200
  end
end
