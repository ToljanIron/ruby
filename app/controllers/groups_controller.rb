require 'oj'
require 'oj_mimic_json'

include SessionsHelper
include CdsGroupsHelper
include CdsUtilHelper

class GroupsController < ApplicationController
  def groups
    authorize :group, :index?

    cid = current_user.company_id
    sid = params[:sid].to_i
    sid = sid == 0 ? Snapshot.last_snapshot_of_company(cid) : sid
    qid = params[:qid]

    cache_key = "groups-comapny_id-cid-#{cid}-sid-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      puts 'Retrieving all groups. Replace with authorized groups only'
      groups_ids = Group.by_snapshot(sid).pluck(:id) if qid.nil?
      groups_ids = Group.by_snapshot(sid).where(questionnaire_id: qid.to_i).pluck(:id) if !qid.nil?

      raise 'empty groups select list' if groups_ids.nil? || groups_ids.length == 0
      res = CdsGroupsHelper.groups_with_sizes(groups_ids)
      cache_write(cache_key, res)
    end
    res = { groups: res }
    render json: Oj.dump(res), status: 200
  end
end
