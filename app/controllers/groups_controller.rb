require 'oj'
require 'oj_mimic_json'

include SessionsHelper
include CdsGroupsHelper
include CdsUtilHelper

class GroupsController < ApplicationController
  def formal_structure
    authorize :group, :index?

    cid = current_user.company_id
    sid = params[:sid].to_i
    sid = sid == 0 ? Snapshot.last_snapshot_of_company(cid) : sid

    cache_key = "formal_structure-cid-#{cid}-sid-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      parent_group_id = Group.get_parent_group(cid, sid).try(:id)
      res = []
      res.push CdsGroupsHelper.convert_formal_structure_to_group_id_child_groups_pairs(parent_group_id)
      cache_write(cache_key, res)
    end
    res = { formal_structure: res }
    render json: Oj.dump(res), status: 200
  end

  def groups
    authorize :group, :index?

    cid = current_user.company_id
    sid = params[:sid].to_i
    sid = sid == 0 ? Snapshot.last_snapshot_of_company(cid) : sid

    cache_key = "groups-comapny_id-cid-#{cid}-sid-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      groups_ids = policy_scope(Group).by_snapshot(sid).select(:id).pluck(:id)

      raise 'empty groups select list' if groups_ids.nil? || groups_ids.length == 0

      company = Company.find(cid)
      res = []
      if (company.questionnaire_only?)
        groups_ids.each do |gid|
          g = Group.find(gid)
          res.push g.pack_to_json
        end
      else
        res = CdsGroupsHelper.groups_with_sizes(groups_ids)
      end
      
      cache_write(cache_key, res)
    end
    res = { groups: res }
    render json: Oj.dump(res), status: 200
  end
end
