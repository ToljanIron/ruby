namespace :db do
  desc 'drop_company'
  task :drop_company, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    cid   = args[:cid]
    raise "Missing cid" if cid.nil?

    puts "Deleting company: #{cid}"
    sid = Snapshot.find_by(company_id: cid).id
    emps = Employee.where(company_id: cid)

    puts "Removing groups"
    Group.where(company_id: cid).delete_all
    puts "Removing CdsMetricScores"
    CdsMetricScore.where(company_id: cid).delete_all
    NetworkSnapshotData.where(snapshot_id: sid).delete_all
    puts "Removing emails"
    EmailSubjectSnapshotData.where(snapshot_id: sid).delete_all
    puts "Removing raw data"
    RawDataEntry.where(company_id: cid).delete_all
    UiLevelConfiguration.where(company_id: cid).delete_all
    NetworkName.where(company_id: cid).delete_all
    CompanyMetric.where(company_id: cid).delete_all
    MetricName.where(company_id: cid).delete_all
    GaugeConfiguration.where(company_id: cid).delete_all
    EmployeeManagementRelation.where(manager_id: emps).delete_all
    EmployeesConnection.where(employee_id: emps).delete_all
    puts "Removing employees"
    Employee.where(company_id: cid).delete_all
    CompanyStatistics.where(snapshot_id: sid).delete_all
    JobTitle.where(company_id: cid).delete_all
    Office.where(company_id: cid).delete_all
    Role.where(company_id: cid).delete_all
    puts "Removing snapshots"
    Snapshot.find(sid).delete
    puts "Removing company"
    Company.find(cid).delete
  end
end
