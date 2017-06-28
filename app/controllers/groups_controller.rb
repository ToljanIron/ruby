include SessionsHelper
include GroupsHelper
include CdsUtilHelper

class GroupsController < ApplicationController
  def formal_structure
    authorize parent_groups, :index?

    cid = current_user.company_id
    sid = params[:sid].to_i || Snapshot.last_snapshot_of_company(cid)

    cache_key = "formal_structure-cid-#{cid}-sid-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      parent_group_id = Group.get_parent_group(cid, sid).id
      res = covert_formal_structure_to_group_id_child_groups_pairs(parent_group_id)
      cache_write(cache_key, res)
    end
    render json: { formal_structure: res }, status: 200
  end

  def groups
    authorize :group, :index?

    cid = current_user.company_id
    sid = params[:sid].to_i || Snapshot.last_snapshot_of_company(cid)

    cache_key = "groups-comapny_id-cid-#{cid}-sid-#{sid}"
    res = cache_read(cache_key)
    if res.nil?
      groups = Group.by_snapshot(sid)
      res = []
      groups.each do |g|
        res.push g.pack_to_json
      end
      cache_write(cache_key, res)
    end
    (0..res.length).each do |index|
      res[index].merge!({selected: false }) unless res[index].nil?
    end
    render json: { groups: res }, status: 200
  end
end
