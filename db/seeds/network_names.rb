cid = Company.last.try(:id) || 1
NetworkName.create!(name: 'Communication Flow', company_id: cid)
