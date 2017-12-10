class NetworkSnapshotDataController < ApplicationController
  include NetworkSnapshotDataHelper

  # API/get_dynamics_employee_map
  def get_dynamics_employee_map
    authorize :network_snapshot_data, :index?
    permitted = params.permit(:interval, :eid, :aid)

    cid = current_user.company_id
    eid = permitted[:eid]
    interval = permitted[:interval]
    aid = Algorithm.get_algorithm_id(permitted[:aid])

    cache_key = "get_dynamics_employee_map-cid-#{cid}-eid-#{eid}-interval-#{interval}-aid-#{aid}"
    puts "cache_key: #{cache_key}"
    res = cache_read(cache_key)
    if res.nil?
      res = get_dynamics_employee_map_from_helper(cid, eid, interval, aid)
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  # API/get_dynamics_map
  def get_dynamics_map
    authorize :network_snapshot_data, :index?
    permitted = params.permit(:interval, :group_name, :aid)

    cid = current_user.company_id
    group_name = permitted[:group_name]
    interval = permitted[:interval]
    aid = Algorithm.get_algorithm_id(permitted[:aid])

    cache_key = "get_dynamics_map-cid-#{cid}-group_name-#{group_name}-interval-#{interval}-aid-#{aid}"
    puts "cache_key: #{cache_key}"
    res = cache_read(cache_key)
    if res.nil?
      res = get_dynamics_map_from_helper(cid, group_name, interval, aid)
      cache_write(cache_key, res)
    end
    render json: Oj.dump(res)
  end

  # API/add_email_relation
  def add_email_relation
    authorize :network_snapshot_data, :update?
    cid = current_user.company_id
    sid = Snapshot.last_snapshot_of_company(cid)
    nid = NetworkName.where(company_id: cid, name: 'Communication Flow').last.id

    from_employee = params[:from_employee]
    to_employee   = params[:to_employee]
    message_id    = params[:message_id]
    from_type     = params[:from_type]
    to_type       = params[:to_type]

    feid = Employee.where(email: from_employee, snapshot_id: sid).last.id
    teid = Employee.where(email: to_employee, snapshot_id: sid).last.id

    nsd = NetworkSnapshotData.create!(
      snapshot_id: sid,
      network_id: nid,
      company_id: cid,
      from_employee_id: feid,
      to_employee_id: teid,
      value: 1,
      message_id: message_id,
      from_type: from_type,
      to_type: to_type,
      multiplicity: 1
    )

    render json: Oj.dump(nsd.as_json)
  end

  # API/delete_email_relation
  def delete_email_relation
    authorize :network_snapshot_data, :update?
    NetworkSnapshotData.find(params[:id]).delete
    render text: 'ok'
  end
end
