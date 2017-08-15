

cid = 11
sid = 96

CdsMetricScore.where(snapshot_id: sid).delete_all
groups = Group.by_snapshot(sid)
algorithms = CompanyMetric.where(company_id: 11).where("algorithm_id >= 700 and algorithm_id < 800").select(:id, :algorithm_id)

heading = 'insert into cds_metric_scores (company_id, employee_id, group_id, snapshot_id, company_metric_id, score, algorithm_id) values'
values = ''
ii = 0

algorithms.each do |algo|
  groups.each do |group|
    gid = group.id
    group.extract_employees.each do |eid|
      score = Random.rand(50).to_f
      values += "(#{cid}, #{eid}, #{gid}, #{sid}, #{algo.id}, #{score}, #{algo.algorithm_id}),"
      if (ii % 200 == 0)
        puts "Row: #{ii}"
        values = values[0..-2]
        sqlstr = "#{heading} #{values}"
        ActiveRecord::Base.connection.exec_query(sqlstr)
        values = ''
      end
      ii += 1
    end
  end
end

puts "Number of new entries: #{CdsMetricScore.where(snapshot_id: sid).count}"
puts 'Done ..'
