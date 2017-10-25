require './lib/tasks/modules/create_comapny_metrics_for_new_algorithms_seed_to_cds_helper.rb'
include CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper

namespace :db do
  desc 'create_company_metrics_seed_to_cds'
  task :create_company_metrics_seed_to_cds, [:cid] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    t_id = ENV['ID'].to_i
    EventLog.log_event(job_id: t_id, message: 'create seed to company metrics started')
    ActiveRecord::Base.transaction do
      begin
        cid = args[:cid] || -1
        company_id = Company.where(id: cid.to_i).first.try(:id)
        fail 'company not exist' unless company_id
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_comapny(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_non_reciprocity(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_sinks(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_gauge_sinks(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_proportion_time_spent_on_meetings(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_proportion_of_managers_never_in_meetings(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_avg_of_subject(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_gauge_information_isolate(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_gauge_non_reciprocity(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_political_power(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_gauge_political_power(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_company_metrics_for_analyze_superposition_graph(company_id)

        # V3
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_gauge_num_of_ppl_in_meetings(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_gauge_avg_time_spent_in_meetings(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_gauge_closeness_level(company_id)
        CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_gauge_synergy_level(company_id)

        EventLog.log_event(job_id: t_id, message: 'create seed to company metrics ended')
      rescue => e
        puts "EXCEPTION: #{e.message}"
        puts e.backtrace.join("\n");
        EventLog.log_event(job_id: t_id, message: 'create seed to company metrics error')
        raise ActiveRecord::Rollback
      end
    end
  end
end
