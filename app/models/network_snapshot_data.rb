class NetworkSnapshotData < ActiveRecord::Base
  belongs_to :company
  belongs_to :network_name
  belongs_to :snapshot
  belongs_to :employee
  belongs_to :questionnaire_question

  FROM_TYPE_INIT    = 1
  FROM_TYPE_REPLY   = 2
  FROM_TYPE_FORWARD = 3

  TO_TYPE_TO  = 1
  TO_TYPE_CC  = 2
  TO_TYPE_BCC = 3

  def original_snapshot
    return Snapshot.find_by(id: original_snapshot_id)
  end

  def NetworkSnapshotData.emails(cid)
    network_id = NetworkName.where(name: "Communication Flow", company_id: cid)[0]
    if network_id === nil
      return -1
    end
    return network_id.id
  end

  def self.create_email_adapter(p={})
    raise 'create_email_adapter must have company_id' if p[:company_id].nil?
    cid = p[:company_id]
    nid = p[:network_id].nil? ? NetworkName.where(company_id: cid, name: 'Communication Flow').last.id : p[:network_id]

    snapshot_id       = p[:snapshot_id]      || -1
    network_id        = nid
    company_id        = cid
    from_employee_id  = p[:employee_from_id] || nil
    to_employee_id    = p[:employee_to_id]   || nil
    (1..18).each do |i|
      tmp = 'n' + i.to_s
      ni_amount = (p[tmp.to_sym])   ||  0
      while ni_amount > 0 do
        message_id = DateTime.now.strftime('%Q')
        multiplicity  = (i/9.to_f).ceil     # 1 for One2One, 2 for One2Mnay
        from_type     = multiplicity == 1 ? (i/3.to_f).ceil : (((i/3.to_f).ceil) - 3)   # 1 for Initiate, 2 for Reply, 3 for Forward
        to_type       = ((i-1) % 3) + 1     # 1 for To, 2 for CC, 3 for BCC

        NetworkSnapshotData.create!(snapshot_id: snapshot_id, network_id: network_id, company_id: company_id,
                                    from_employee_id: from_employee_id, to_employee_id: to_employee_id, value: 1,
                                    message_id: message_id, multiplicity: multiplicity, from_type: from_type, to_type: to_type)
        ni_amount -= 1
      end
    end
  end

  def self.show_emails(cid, gid, from_email_filter, sid)
    nid = NetworkName.where(company_id: cid, name: 'Communication Flow').last.id
    gid = Group.by_snapshot(sid).where(parent_group_id: nil).first.id if gid == -1
    empids = Group.find(gid).extract_employees

    ret = NetworkSnapshotData
            .select(:id,:from_employee_id, :to_employee_id, :message_id, :multiplicity, :from_type, :to_type)
            .joins("left join employees as emps on emps.id = from_employee_id")
            .where("network_snapshot_data.company_id = #{cid}")
            .where(snapshot_id: sid)
            .where(network_id: nid)
            .where(from_employee_id: empids, to_employee_id: empids)
            .where("emps.email like '%#{from_email_filter}%'").limit(100)
    return ret
  end
end
