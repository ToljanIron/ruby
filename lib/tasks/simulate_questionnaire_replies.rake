require './app/helpers/simulator_helper.rb'

namespace :db do
  include SimulatorHelper

  desc 'simulate_questionnaire_replies'
  task :simulate_questionnaire_replies, [:sid] => :environment do |t, args|
    sid = args[:sid]
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    SimulatorHelper.simulate_questionnaire_replies(sid)
    puts "Done .."
  end
end
