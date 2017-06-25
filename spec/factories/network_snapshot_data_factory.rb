FactoryGirl.define do
  factory :network_snapshot_data do
    from_employee_id 1
    to_employee_id 2
    snapshot_id 1
    network_id 1
    company_id 1
    value Random.rand(2)
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
def fg_multi_create_network_snapshot_data(empsnum, traffic_density = 3)
  (1..empsnum).each do |i|
    (1..empsnum).each do |j|
      value = ((i + j) % (5 - traffic_density) == 0) ? 1 : 0
      FactoryGirl.create(:network_snapshot_data, from_employee_id: i, to_employee_id: j, value: value)
    end
  end
end
