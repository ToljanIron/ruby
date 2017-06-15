require './app/helpers/jobs_helper.rb'
include JobsHelper

namespace :db do
  desc 'backup seleced tables'
  task backup_selected_tables: :environment do
    t_id = ENV['ID'].to_i
	   config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
     ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
    	begin
        start_job(t_id) if t_id != 0
    	  `backup perform --trigger db_backup`
    	  # TODO: test restore data
    	  finish_job(t_id) if t_id != 0
    	rescue => e
          finish_job_with_error(t_id) if t_id != 0
        raise ActiveRecord::Rollback
      end
    end
  end
end
