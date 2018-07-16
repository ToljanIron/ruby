require 'csv'
require 'zip'
require 'json'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    delete_last_questionnaire

  end
end

def delete_last_questionnaire

  quest = Questionnaire.last
  qid = quest.questionnaire_id
  sid = quest.snapshot_id

  puts "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
  puts "Working on questionnaire: #{qid}, sid: #{sid}"
  puts "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

  ActiveRecord::Base.transaction do
    Snapshot.find(sid).delete
    Employee.where(snapshot_id: sid).delete_all
    Group.where(snapshot_id: sid).delete_all
    NetworkName.where(questionnaire_id: qid).delete_all
    QuestionnaireQuestion.where(questionnaire_id: qid).delete_all
    QuestionReply.where(questionnaire_id: qid).delete_all
    QuestionnaireParticipant.where(questionnaire_id: qid).delete_all
    Questionnaire.find(qid).delete
  end
end
