
namespace :db do
  require './app/helpers/questionnaire_helper.rb'
  include QuestionnaireHelper

  desc 'fix_cold_questionnaires'
  task :fix_cold_questionnaires, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    QuestionnaireHelper.find_and_fix_cold_questionnaires
  end
end

