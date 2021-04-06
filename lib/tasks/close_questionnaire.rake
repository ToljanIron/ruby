namespace :db do
	require 'sidekiq/api'
	desc 'close questionnaire job'
	task :close_questionnaire, [:qid] => :environment do |t, args|
		job = Sidekiq::Queue.new("close_questionnaire").first
		if job
			Rails.logger.info "Started at #{Time.now}"
			job.klass.constantize.new.perform(*job.args)
			job.delete
			Rails.logger.info "Finished at #{Time.now}"
		end
	end
end