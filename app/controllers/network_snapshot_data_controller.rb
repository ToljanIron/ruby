class NetworkSnapshotDataController < ApplicationController

  # API/show_emails_network
  def show_emails_network
    authorize :network_snapshot_data, :index?
    cid = current_user.company_id
    gid = params[:gid].to_i
    from_email_filter = params[:from_email_filter] || ''
    cache_key = "show_email_network-#{cid}"
    res = cache_read(cache_key)
    if res.nil?
      res = NetworkSnapshotData.show_emails(cid, gid, from_email_filter).as_json
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
