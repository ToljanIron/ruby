require './app/helpers/populate_questionnaire_helper.rb'

namespace :db do
  desc 'populate questionnaire'
  task :populate_questionnaire, [:cid] => :environment do |t, args|
    cid = args[:cid]
    t_id = ENV['ID'].to_i
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    begin
      raise 'Please specify company id' if cid.nil?
      # do stuff with cid
      PopulateQuestionnaireHelper.run(cid)
      puts "Done .."
    rescue => e
      puts e.message
      puts e.backtrace.join("\n")
    end
  end
end
