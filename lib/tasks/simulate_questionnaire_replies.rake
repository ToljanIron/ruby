namespace :db do
  DENSITY = 0.6

  desc 'simulate_questionnaire_replies'
  task :simulate_questionnaire_replies, [:sid] => :environment do |t, args|
    sid = args[:sid]
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        raise 'missing snapshot ID' if sid.nil?
        qid = Questionnaire.where(snapshot_id: sid).last.try(:id)
        raise "Did not find a questionnaire for sid: #{sid}" if qid.nil?
        qpids = QuestionnaireParticipant
                  .where(questionnaire_id: qid, active: true)
                  .where.not(employee_id: -1)
                  .pluck(:id)
        qqids = QuestionnaireQuestion.where(questionnaire_id: qid, active: true).pluck(:id)

        QuestionReply.where(questionnaire_id: qid).delete_all

        num_nodes = qpids.length
        possible_connections = (num_nodes * (num_nodes - 1))
        qqids.each do |qqid|
          puts "======================================"
          puts "Working on question ID: #{qqid}"
          puts "======================================"
          counter = 0
          qpids.each do |fqpid|
            qpids.each do |tqpid|
              next if fqpid == tqpid
              next if rand > DENSITY
              puts "   pair: from participant ID: #{fqpid}, to participant ID: #{tqpid}"
              QuestionReply.create!(
                questionnaire_id: qid,
                questionnaire_question_id: qqid,
                questionnaire_participant_id: fqpid,
                reffered_questionnaire_participant_id: tqpid,
                answer: 1
              )
              counter += 1
            end
          end

          puts "Create #{counter} edges out of #{possible_connections}. Density is: #{(counter.to_f / possible_connections).round(2)}"
        end

        QuestionnaireParticipant.where(id: qpids).update_all(status: :completed)
      rescue => e
        puts e.message
        puts e.backtrace.join("\n")
      end
    end
    puts "Done .."
  end
end
