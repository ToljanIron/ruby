# frozen_string_literal: true

require 'faker'

sid=145
cid=11

## Clear old data
puts "Deleting old alerts"
Alert.where(snapshot_id: sid).delete_all

## Create new data
puts "Going to create 10 meetings now"
gids = Group.where(snapshot_id: sid).select(:id).pluck(:id)
cmids = CompanyMetric.where(algorithm_id: [200, 201, 203, 204, 205, 206, 207]).pluck(:id)

(0..10).each do |ii|
  puts "Alert number: #{ii}"
  Alert.create!(
    company_id: cid,
    snapshot_id: sid,
    group_id: gids.sample,
    alert_type: 1,
    company_metric_id: cmids.sample,
    direction: (ii % 2) + 1,
    state: 0
  )
end
