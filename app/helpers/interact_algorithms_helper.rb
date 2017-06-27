include AlgorithmsHelper

module InteractAlgorithmsHelper
  def calculate_network_indegree(cid, sid, nid, gid)
    emps = AlgorithmsHelper.get_members_in_group(-1, gid, cid)
    return [] if emps.empty?

    sqlstr =
      "SELECT emp.id AS employee_id, coalesce(sum(value), 0) AS score
       FROM employees AS emp
       LEFT JOIN (
                  SELECT from_employee_id, value
                  FROM network_snapshot_data AS nsd
                  WHERE
                  nsd.network_id  = #{nid} AND
                  nsd.snapshot_id = #{sid} AND
                  nsd.from_employee_id IN (#{emps.join(',')}) AND
                  nsd.to_employee_id   IN (#{emps.join(',')})
                  ) AS nsdjoin ON nsdjoin.from_employee_id = emp.id
       WHERE emp.id IN (#{emps.join(',')}) AND
             emp.snapshot_id = #{sid}
       GROUP BY emp.id"
    indeg = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    indeg
  end

  def calculate_network_outdegree(cid, sid, nid, gid)
    emps = AlgorithmsHelper.get_members_in_group(-1, gid, cid)
    return [] if emps.empty?

    sqlstr =
      "SELECT emp.id AS employee_id, coalesce(sum(value), 0) AS score
       FROM employees AS emp
       LEFT JOIN (
                  SELECT to_employee_id, value
                  FROM network_snapshot_data AS nsd
                  WHERE
                  nsd.network_id  = #{nid} AND
                  nsd.snapshot_id = #{sid} AND
                  nsd.from_employee_id IN (#{emps.join(',')}) AND
                  nsd.to_employee_id   IN (#{emps.join(',')})
                  ) AS nsdjoin ON nsdjoin.to_employee_id = emp.id
       WHERE emp.id IN (#{emps.join(',')}) AND
             emp.snapshot_id = #{sid}
       GROUP BY emp.id"
    outdeg = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    outdeg
  end
end
