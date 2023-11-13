FactoryBot.define do
  factory :network_snapshot_data do
    from_employee_id { 1 }
    to_employee_id { 2 }
    snapshot_id { 1 }
    network_id { 1 }
    company_id { 1 }
    value { Random.rand(2) }
  end
end

def create_email_connection(from_id, to_id, from_type, to_type, sid, cid, nid, value=1)
  NetworkSnapshotData.create(from_employee_id: from_id, to_employee_id: to_id, from_type: from_type,
    to_type: to_type, snapshot_id: @s.id, company_id: cid, network_id: nid, value: value)
end

############################################################
##
## create empsnum x empsnum matrix of email traffic.
## traffic_density will determine every how many entries we
## will have a none zero entry
## traffic_density should be a number between 0-5
##
############################################################
# def fg_multi_create_network_snapshot_data(empsnum, traffic_density = 3)
def fg_multi_create_network_snapshot_data(empsnum, sid, cid, nid, traffic_density)
  (1..empsnum).each do |i|
    (1..empsnum).each do |j|
      next if i == j
      value = ((i + j) % (5 - traffic_density) == 0) ? 1 : 0
      FactoryBot.create(:network_snapshot_data,
        from_employee_id: i,
        to_employee_id: j,
        value: value,
        snapshot_id: sid,
        company_id: cid,
        network_id: nid
        )
    end
  end
end

###################################################
## Create emails in emails_snapshot_data according to an input matrix
###################################################
def fg_emails_from_matrix(all, p = nil)
  raise 'null argument all' if all.nil?
  raise 'empty argument all' if all.empty?
  dim = all.length
  raise 'Matrix dimentions are not equal' if dim != all.first.length

  p = p || {}
  cid = p[:cid] || 1
  sid = p[:sid] || 1
  nid = p[:nid] || 1

  all.each_with_index do |row, i|
    row.each_with_index do |n, j|
      if (i != j)
        n.times do
          FactoryBot.create(
            :network_snapshot_data,
            from_employee_id: i + 1,
            to_employee_id: j + 1,
            value: 1,
            company_id: cid,
            network_id: nid,
            snapshot_id: sid,
            multiplicity: 1,
            from_type: 1,
            to_type: 1,
          )
        end
      end
    end
  end
end
