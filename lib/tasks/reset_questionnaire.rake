namespace :db do
  desc 'reset_questionnaire'
  task :reset_questionnaire, [:qid] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        qid = args[:qid]
        if qid.nil?
          fail 'questionnaire id wasnt given'
      else
        QuestionnaireHelper.delete_all_replies(qid)
        end
      rescue => e
        puts 'got exception:', e.message, e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
