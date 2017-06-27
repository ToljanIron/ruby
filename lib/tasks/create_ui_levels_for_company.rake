require './lib/tasks/modules/create_snapshot_helper.rb'
require './app/helpers/cds_util_helper.rb'

namespace :db do
  desc 'create_ui_levels_for_company'
  task :create_ui_levels_for_company, [:cid, :quest_only, :date, :type] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    cid        = args[:cid]  || ENV['COMPANY_ID'] || (fail 'No company ID given (cid)')
    quest_only = args[:quest_only]  || false
    puts "Running with CID=#{cid}"
    CdsUtilHelper.cache_delete_all
    ActiveRecord::Base.transaction do
      begin
        if quest_only == false
          puts "Running regular ui levels"
          CreateUiLevelsHelper::create_ui_level(cid.to_i)
        else
          puts "Running ui levels for questionnaire only company"
          CreateUiLevelsQuestionnaireOnlyHelper::create_ui_level_questionnaire_only(cid.to_i)
        end
      rescue => e
        error = e.message
        puts "got exception: #{error}"
        puts e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
