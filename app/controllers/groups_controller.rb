include SessionsHelper
include GroupsHelper
include UtilHelper

class GroupsController < ApplicationController
  def formal_structure
    parent_groups = groupscope.where(parent_group_id: nil)
    authorize parent_groups, :index?
    res = []
    parent_groups.each do |g|
      res.push covert_formal_structure_to_group_id_child_groups_pairs g.id
    end
    render json: { formal_structure: res }, status: 200
  end

  def groups
    authorize :group, :index?

    company_id = current_user.company_id
    cache_key = "groups-comapny_id-#{company_id}"
    res = cache_read(cache_key)
    if res.nil?
      groups = groupscope
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

  private

  def groupscope
    GroupPolicy::Scope.new(current_user, Group).resolve
  end
end
