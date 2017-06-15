namespace :db do
  require './app/helpers/jobs_helper.rb'
  include JobsHelper
  
  desc 'keep_alive_task'
  task keep_alive_task: :environment do
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    t_id = ENV['ID'].to_i
    ActiveRecord::Base.transaction do
      begin
        start_job(t_id) if t_id != 0
        query = "select *
                 from api_clients as ac
                 inner join api_client_configurations as acc on ac.api_client_configuration_id = acc.id
                 where (now() - (acc.report_if_not_responsive_for * '1 minute'::INTERVAL)) > ac.last_contact"

        col = ActiveRecord::Base.connection.execute(query)
        col.each do |dead_api|
          EventLog.log_event(event_type_name: 'ERROR', message: "client: #{dead_api['client_name']} is dead, no response for over #{dead_api['report_if_not_responsive_for']} minutes. api config id: #{dead_api['api_client_configuration_id']}")
        end
      rescue Exception => e
        finish_job_with_error(t_id) if t_id != 0
        raise ActiveRecord::Rollback
      end
    end
  end
end
