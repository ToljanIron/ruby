# require './app/helpers/jobs_helper.rb'
# include JobsHelper

# namespace :db do
#   desc 'archive old jobs'
#   task revcovery_email_collection_task: :environment do |t, args|
#     t_id = ENV['ID'].to_i
#     config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
#     ActiveRecord::Base.establish_connection(config)
#     ActiveRecord::Base.transaction do
#       begin
#         EventLog.log_event(job_id: t_id, message: 'revcovery_email_collection_task statred')
#         start_job(t_id) if t_id != 0
#         puts 'ok'
#         # JobsHelper.archive_jobs
#         # finish_job(t_id) if t_id != 0
#       rescue => e
#         finish_job_with_error(t_id) if t_id != 0
#         raise ActiveRecord::Rollback
#       end
#     end
#   end
# end
