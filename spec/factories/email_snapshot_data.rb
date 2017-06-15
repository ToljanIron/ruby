FactoryGirl.define do
  factory :email_snapshot_data do
    employee_from_id 1
    employee_to_id 2
    snapshot_id 1
    significant_level :not_significant
    n1 1
    n2 1
  end
end

############################################################
##
## create empsnum x empsnum matrix of email traffic.
## traffic_density will determine every how many entries we
## will have a none zero entry
## traffic_density should be a number between 0-5
##
############################################################
def fg_multi_create_email_snapshot_data(empsnum, traffic_density = 3, sid)
  (1..empsnum).each do |i|
    (1..empsnum).each do |j|
      value = (((i + j) % (5 - traffic_density)) == 0) ? 1 : 0
      NetworkSnapshotData.create_email_adapter(snapshot_id: sid, employee_from_id: i, employee_to_id: j, n1: value)
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
  sid = p[:sid] || 1

  (0..dim-1).each do |i|
    (0..dim-1).each do |j|
      NetworkSnapshotData.create_email_adapter(employee_from_id: i, employee_to_id: j, n1: all[i][j], n2: 0, snapshot_id: sid) if i != j && all[i][j] > 0
    end
  end
end
