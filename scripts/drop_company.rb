COMPANY_NAME = 'Company'

cid = Company.find_by(name: COMPANY_NAME).id
sid = Snapshot.find_by(company_id: cid).id
emps = Employee.where(company_id: cid)



Group.where(company_id: cid).delete_all
CdsMetricScore.where(company_id: cid).delete_all
NetworkSnapshotData.where(snapshot_id: sid).delete_all
EmailSubjectSnapshotData.where(snapshot_id: sid).delete_all
RawDataEntry.where(company_id: cid).delete_all
UiLevelConfiguration.where(company_id: cid).delete_all
NetworkName.where(company_id: cid).delete_all
CompanyMetric.where(company_id: cid).delete_all
MetricName.where(company_id: cid).delete_all
GaugeConfiguration.where(company_id: cid).delete_all
EmployeeManagementRelation.where(manager_id: emps).delete_all
EmployeesConnection.where(employee_id: emps).delete_all
Employee.where(company_id: cid).delete_all
CompanyStatistics.where(snapshot_id: sid).delete_all
JobTitle.where(company_id: cid).delete_all
Office.where(company_id: cid).delete_all
Role.where(company_id: cid).delete_all
Snapshot.find(sid).delete
Company.find(cid).delete
