require 'csv'
require 'zip'
require 'json'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    ### convert_data

    fix_nids

  end
end

TO_CID = 16

def fix_nids
  nids = NetworkName.where(company_id: 16).pluck(:id)
  nids.each do |nid|

    puts "Working on nid: #{nid}"
    sid = NetworkSnapshotData.where(network_id: nid).try(:last).try(:snapshot_id)
    puts "    Found sid: #{sid}"
    next if sid.nil?
    qid = Questionnaire.where(snapshot_id: sid).last.id

    NetworkName.find(nid).update!(questionnaire_id: qid)
  end
end

def convert_data
  cidDets = {
    '16' => {sid: 82,  qid: 28},
    '17' => {sid: 118, qid: 32},
    '18' => {sid: 84,  qid: 31},
    '19' => {sid: 122, qid: 36},
    '20' => {sid: 124, qid: 33},
    '22' => {sid: 123, qid: 37}
  }

  #[17, 18, 19, 20 ,22].each do |fcid|
  [22].each do |fcid|

    sid = cidDets[fcid.to_s][:sid]
    qid = cidDets[fcid.to_s][:qid]
    puts "======================================"
    puts "Snapshot: #{sid}, quest: #{qid}"
    puts "======================================"


    ActiveRecord::Base.transaction do
      puts "Working on Snapshots"
      Snapshot.where(company_id: fcid).update_all(company_id: TO_CID)

      puts "Working on Emps"
      Employee.where(company_id: fcid).update_all(company_id: TO_CID, snapshot_id: sid)

      puts "Working on job_titles"
      JobTitle.where(company_id: fcid).update_all(company_id: TO_CID)

      puts "Working on roles"
      Role.where(company_id: fcid).update_all(company_id: TO_CID)

      puts "Working on offices"
      Office.where(company_id: fcid).update_all(company_id: TO_CID)

      puts "Working on Groups"
      Group.where(company_id: fcid).update_all(company_id: TO_CID, snapshot_id: sid)

      puts "Working on NetworkName"
      NetworkName.where(company_id: fcid).update_all(company_id: TO_CID)

      puts "Working on MetricName"
      MetricName.where(company_id: fcid).update_all(company_id: TO_CID)

      puts "Working on company_metrics"
      CompanyMetric.where(company_id: fcid).update_all(company_id: TO_CID)

      puts "Working on questionnaires"
      Questionnaire.find(qid).update(company_id: TO_CID, snapshot_id: sid)

      puts "Working on questionnaires"
      QuestionnaireQuestion.where(questionnaire_id: qid).update(company_id: TO_CID)

      puts "Working on questions"
      Question.where(company_id: fcid).update_all(company_id: TO_CID)
    end


    puts "Working on network_snapshot_data"
    NetworkSnapshotData.where(company_id: fcid).update_all(company_id: TO_CID)

    puts "Workin on CdsMetricScore"
    CdsMetricScore.where(company_id: fcid).update_all(company_id: TO_CID, snapshot_id: sid)

  end
end
