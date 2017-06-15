class DashboardController < ApplicationController
  NO_GROUP = -1
  NO_SNAPSHOT = -1
  PLUS_SIGN = '+'.freeze
  DIFFRENCE_DYAD = 'Difference dyad'.freeze
  QUARTELY_CHANGE_DYAD = 'Quarterly change dyad'.freeze

  def tree_map
    authorize :dashboard, :index?
    current_company = Company.find(current_user.company_id)
    gid = current_company.groups.select { |g| g.parent_group_id.nil? }[0].id if !params[:group_id]
    cache_key = "tree_map-#{current_company.id}-#{gid || params[:group_id]}-#{params[:snapshot_id]}"
    data = cache_read(cache_key)
    unless data
      data = cache_read(cache_key)
      data = DashboardHelper.build_tree_map(gid, params[:snapshot_id]) unless params[:snapshot_id].blank?
      data = DashboardHelper.build_tree_map(gid) if params[:snapshot_id].blank?
      cache_write(cache_key, data)
    end
    render json: data
  end

  def dyads_with_the_biggest_diff
    authorize :dashboard, :index?
    cid = current_user.company_id
    gid = params[:gid].to_i
    sid = params[:snapshot_id].to_i
    sid = NO_SNAPSHOT if sid == 0
    gid = Group.where(company_id: cid, parent_group_id: nil).first.try(:id) if gid == 0
    raise 'there is no parent group in company' unless gid
    cache_key = "dyads_with_the_biggest_diff-#{cid}-#{gid}-#{sid}"
    data = cache_read(cache_key)
    if data.nil?
      # curr_snapshot = Snapshot.find(sid)
      # last_sid = Snapshot.where(company_id: cid).where('timestamp < ?', curr_snapshot[:timestamp]).order('timestamp desc').first.try(:id)
      # last_month_communication_volumes = DashboardHelper.most_communication_volumes_diff_between_dayds(gid, last_sid)
      communication_volumes = DashboardHelper.most_communication_volumes_diff_between_dayds(gid, sid)
      most_communication_volumes = communication_volumes.take(3)
      if most_communication_volumes.empty?
        render json: { msg: 'All departments are reciprocal' }
        return
      else
        most_communication_volumes.each do |dyad|
          dyad[:dynamic_diff] = DashboardHelper.calculate_diff_with_last_month(dyad, gid, sid)
        end
        data = DashboardHelper.create_json_structure(most_communication_volumes, DIFFRENCE_DYAD)
        cache_write(cache_key, data)
      end
    end
    render json: { data: data }
  end

  def communication_volume_changes_between_dyads
    authorize :dashboard, :index?
    cid = current_user.company_id
    gid = params[:gid].to_i
    type = params[:type].to_i
    gid = Group.where(company_id: cid, parent_group_id: nil).first.try(:id) if gid.zero?
    raise 'there is no parent group in company' unless gid
    s_1_id = Snapshot.where(company_id: cid, snapshot_type: nil).order('timestamp desc').first.try(:id)
    s_2_id = DashboardHelper.fetch_snapshot_from_type(s_1_id, cid, type)
    cache_key = "communication_volume_changes_between_dyads-#{cid}-#{gid}-#{s_1_id}-#{s_2_id}"
    data = cache_read(cache_key)
    if data.nil?
      if s_1_id && s_2_id
        communication_volumes_diff_between_dayds_in_s1 = DashboardHelper.most_communication_volumes_diff_between_dayds(gid, s_1_id, PLUS_SIGN)
        communication_volumes_diff_between_dayds_in_s2 = DashboardHelper.most_communication_volumes_diff_between_dayds(gid, s_2_id, PLUS_SIGN)
        res = DashboardHelper.communication_volumes_diff_between_dayds_in_2_snapshots(communication_volumes_diff_between_dayds_in_s1, communication_volumes_diff_between_dayds_in_s2)
        top_5_communication_volumes = res.take(5)
        data = DashboardHelper.create_json_structure(top_5_communication_volumes, QUARTELY_CHANGE_DYAD, s_1_id, s_2_id)
      else
        data = []
      end
      cache_write(cache_key, data)
    end
    render json: { data: data }
  end
end
