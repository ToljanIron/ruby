class DropOldTables < ActiveRecord::Migration[5.1]
  def up
    drop_if_exists(:api_client_configurations)
    drop_if_exists(:api_client_task_definitions)
    drop_if_exists(:api_clients)
    drop_if_exists(:archived_api_client_tasks)
    drop_if_exists(:credentials)
    drop_if_exists(:external_data_metrics)
    drop_if_exists(:external_data_scores)
    drop_if_exists(:filter_keywords)
    drop_if_exists(:gauge_configurations)
    drop_if_exists(:job_to_api_client_task_convertors)
    drop_if_exists(:jobs_archives)
    drop_if_exists(:qpstatus)
    drop_if_exists(:qualifications)
    drop_if_exists(:questionnaire_raw_data)
    drop_if_exists(:reoccurrences)
    drop_if_exists(:scheduled_api_client_tasks)
    drop_if_exists(:sms_messages)
    drop_if_exists(:stack_of_images)
    drop_if_exists(:ui_level_configurations)
  end

  def drop_if_exists(tbl)
    puts "dropping table: #{tbl}"
    drop_table tbl if ActiveRecord::Base.connection.table_exists?(tbl)
  end
end
