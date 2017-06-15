FactoryGirl.define do
  factory :snapshot do
    company_id 1
    name 'Monthly 2015-01-01'
    snapshot_type 1
    timestamp Time.now
    status 2
  end
end

def snapshot_factory_create(p = nil)
  return Snapshot.create!(name: 'snapshot-test', company_id: 1) if p.nil?
  p ||= {}
  p[:name]       ||= 'snapshot-test'
  p[:company_id] ||= 1
  p[:snapshot_type] ||= 3

  return Snapshot.create!(name: p[:name], company_id: p[:company_id]) if p[:id].nil?
  s = Snapshot.find_by(id: p[:id])
  return s if !s.nil?
  return Snapshot.create!(id: p[:id], name: p[:name], company_id: p[:company_id])
end
