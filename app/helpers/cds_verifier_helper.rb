module CdsVerifierHelper
  def self.verify(cid, old_metric_id, algo_id)
    employees = Employee.where(company_id: cid)
    employees.each do |emp|
      CdsMetricScore.where(company_id: cid, algorithm_id: algo_id, employee_id: emp.id).each do |cds_row|
        return cds_row.id if MetricScore.find_by(metric_id: old_metric_id, snapshot_id: cds_row.snapshot_id, company_id: cid, employee_id: emp.id, score: cds_row.score).nil? 
      end
    end
    return false if employees.empty?
    return true
  end
end


#####
#[61,4]
#[62,3]
#[63,7]

#[71,25]




#[64,14]
#[65,15]
#[66,12]
#[67,13]
#[68,18]
#[69,19]
#[70,26]
#[60,28]
#[72, 8]
#[73, 9]
#[74,10]
#[81,30]

#[83,31]

#[79,32]

#[80,33]
#[82,34]

#[86,22]
#[87,23]
#[88,24]