require './app/helpers/jobs_helper.rb'
require './app/helpers/populate_questionnaire_helper.rb'
include JobsHelper

namespace :db do
  desc 'populate questionnaire'
  task :populate_questionnaire, [:cid] => :environment do |t, args|
    cid = args[:cid]
    t_id = ENV['ID'].to_i
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    begin
      start_job(t_id) if t_id != 0
      raise 'Please specify company id' if cid.nil?
      # do stuff with cid
      PopulateQuestionnaireHelper.run(cid)
      finish_job(t_id) if t_id != 0
      puts "Done .."
    rescue => e
      puts e.message
      puts e.backtrace.join("\n")
      finish_job_with_error(t_id) if t_id != 0
    end
  end
end
