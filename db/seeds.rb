# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Metrics
# Metric.create(name: 'Collaboration', metric_type: 'measure', index: 1) if Metric.where(metric_type: 'measure', index: 1).empty?
# Metric.create(name: 'Most Isolated', metric_type: 'measure', index: 2) if Metric.where(metric_type: 'measure', index: 2).empty?
# Metric.create(name: 'Most Social Power', metric_type: 'measure', index: 3) if Metric.where(metric_type: 'measure', index: 3).empty?
# Metric.create(name: 'Most Expert', metric_type: 'measure', index: 4) if Metric.where(metric_type: 'measure', index: 4).empty?
# Metric.create(name: 'Centrality', metric_type: 'measure', index: 5) if Metric.where(metric_type: 'measure', index: 5).empty?
# Metric.create(name: 'Central', metric_type: 'measure', index: 6) if Metric.where(metric_type: 'measure', index: 6).empty?
# Metric.create(name: 'Most Trusted', metric_type: 'measure', index: 7) if Metric.where(metric_type: 'measure', index: 7).empty?
# Metric.create(name: 'Most Trusting', metric_type: 'measure', index: 8) if Metric.where(metric_type: 'measure', index: 8).empty?
# Metric.create(name: 'In The Loop', metric_type: 'measure', index: 9) if Metric.where(metric_type: 'measure', index: 9).empty?
# Metric.create(name: 'Politician', metric_type: 'measure', index: 10) if Metric.where(metric_type: 'measure', index: 10).empty?
# Metric.create(name: 'Total Activity Centrality', metric_type: 'measure', index: 11) if Metric.where(metric_type: 'measure', index: 11).empty?
# Metric.create(name: 'Delegator', metric_type: 'measure', index: 12) if Metric.where(metric_type: 'measure', index: 12).empty?
# Metric.create(name: 'Knowledge Distributor', metric_type: 'measure', index: 13) if Metric.where(metric_type: 'measure', index: 13).empty?
# Metric.create(name: 'Politically Active', metric_type: 'measure', index: 14) if Metric.where(metric_type: 'measure', index: 14).empty?
# Metric.create(name: 'At Risk of Leaving', metric_type: 'flag', index: 0) if Metric.where(metric_type: 'flag', index: 0).empty?
# Metric.create(name: 'Most Promising Talent', metric_type: 'flag', index: 1) if Metric.where(metric_type: 'flag', index: 1).empty?
# Metric.create(name: 'Most Bypassed Manager', metric_type: 'flag', index: 2) if Metric.where(metric_type: 'flag', index: 2).empty?
# Metric.create(name: 'Team Glue', metric_type: 'flag', index: 3) if Metric.where(metric_type: 'flag', index: 3).empty?
# Metric.create(name: 'Collaboration', metric_type: 'analyze', index: 0) if Metric.where(metric_type: 'analyze', index: 0).empty?
# Metric.create(name: 'Friendship', metric_type: 'analyze', index: 1) if Metric.where(metric_type: 'analyze', index: 1).empty?
# Metric.create(name: 'Social Power', metric_type: 'analyze', index: 2) if Metric.where(metric_type: 'analyze', index: 2).empty?
# Metric.create(name: 'Expert', metric_type: 'analyze', index: 3) if Metric.where(metric_type: 'analyze', index: 3).empty?
# Metric.create(name: 'Trust', metric_type: 'analyze', index: 4) if Metric.where(metric_type: 'analyze', index: 4).empty?
# Metric.create(name: 'Centrality', metric_type: 'analyze', index: 5) if Metric.where(metric_type: 'analyze', index: 5).empty?
# Metric.create(name: 'Central', metric_type: 'analyze', index: 6) if Metric.where(metric_type: 'analyze', index: 6).empty?
# Metric.create(name: 'In The Loop', metric_type: 'analyze', index: 7) if Metric.where(metric_type: 'analyze', index: 7).empty?
# Metric.create(name: 'Politician', metric_type: 'analyze', index: 8) if Metric.where(metric_type: 'analyze', index: 8).empty?
# Metric.create(name: 'Most Isolated Group', metric_type: 'group_measure', index: 0) if Metric.where(metric_type: 'group_measure', index: 0).empty?
# Metric.create(name: 'Most Aloof Group', metric_type: 'group_measure', index: 1) if Metric.where(metric_type: 'group_measure', index: 1).empty?
# Metric.create(name: 'Most Self-Sufficient Group', metric_type: 'group_measure', index: 2) if Metric.where(metric_type: 'group_measure', index: 2).empty?

# test for backup..
# for i in 1..1000000 do
# 	hash = {}
# 	hash.store('company_id', 10000)
# 	hash.store('msg_id', 'abcdefghijeclmnopqrstvuwxyz' + i.to_s)
# 	hash.store('from', 'google_company_test@goog.com' + i.to_s)
# 	hash.store('to', ["'google_company_test@goog.com' + #{i}", "'google_company2_test@goog.com' + #{i}"])
# 	hash.store('cc', ["'google_company_cc_test@goog.com' + #{i}", "'google_company2_cc_test@goog.com' + #{i}"])
# 	hash.store('bcc', ["google_company_bcc_test@goog.com' + #{i}"])
# 	hash.store('priority', rand(1...9))
# 	hash.store('date',  Date.new)
# 	RawDataEntry.create(hash)
# 	# RawDataEntry.create(company_id: 1000,
# 	# 					msg_id: 'abcdefghijeclmnopqrstvuwxyz' + i.to_s,
# 	# 					from: 'google_company_test@goog.com' + i.to_s,
# 	# 					to: "['google_company_test@goog.com' + #{i}, 'google_company2_test@goog.com' + #{i}]",
# 	# 					cc: "['google_company_cc_test@goog.com' + #{i}, 'google_company2_cc_test@goog.com' + #{i}]",
# 	# 					bcc: "google_company_bcc_test@goog.com' + #{i}",
# 	# 					priority: rand(1...9),
# 	# 					date: Date.new)
# end

# Configuration
Configuration.create(name: 'email_average_time', value: 12) if Configuration.where(name: 'email_average_time', value: 12).empty?
# ASAF BYEBUG dead file?
# begin
# WEEK = 60 * 24 * 7
# HOUR = 60
# Job.create(type_id: 1, credential_id: 1, next_run: DateTime.now, diff: 4, order_type: false)
# Job.create(type_id: 2, credential_id: 1, next_run: DateTime.now, diff: 4, order_type: false)
# Job.create(type_id: 4, credential_id: 1, next_run: DateTime.now, diff: 24, order_type: false)
# Job.create(type_id: 5, credential_id: -1, next_run: DateTime.now, diff: WEEK, order_type: false)
# Job.create(type_id: 101, credential_id: 1, next_run: DateTime.now, diff: 60, order_type: true)
# Job.create(type_id: 200, credential_id: 1, next_run: DateTime.now, diff: 60, order_type: true)
# Job.create(type_id: 300, credential_id: 1, next_run: DateTime.now, diff: 60, order_type: true)
# Job.create(type_id: 301, credential_id: 1, next_run: DateTime.now, diff: 60, order_type: true)
# end
