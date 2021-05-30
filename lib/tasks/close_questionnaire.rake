namespace :db do
	require 'sidekiq/api'
	desc 'close questionnaire job'
	task :close_questionnaire, [:qid] => :environment do |t, args|
		queue = Sidekiq::Queue.new("close_questionnaire")
		queue.each do |job|
			Rails.logger.info "Started at #{Time.now}"
			job.klass.constantize.new.perform(*job.args)
			job.delete
			Rails.logger.info "Finished at #{Time.now}"
		end
	end
end