namespace :db do
	require 'sidekiq/api'
	desc 'close questionnaire job'
	task :close_questionnaire, [:qid] => :environment do |t, args|
		job = Sidekiq::Queue.new("default").first
		if job
			job.klass.constantize.new.perform(*job.args)
			job.delete
		end
	end
end