namespace :db do
  require './lib/tasks/modules/precalculate_metric_scores_for_custom_data_system_helper.rb'
  require './app/helpers/jobs_helper.rb'
  require './app/helpers/cds_util_helper.rb'
  include PrecalculateMetricScoresForCustomDataSystemHelper
  include JobsHelper
  include CdsUtilHelper

  desc 'precalculate_metric_scores_for_custom_data_system'
  task :precalculate_metric_scores_for_custom_data_system, [:cid, :gid, :pid, :mid, :sid, :rewrite, :calc_all] => :setup_logger do |t, args|
    error = 1
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    t_id = ENV['ID'].to_i
    status = nil
    EventLog.log_event(job_id: t_id, message: 'precalculate_metric_scores_for_custom_data_system_helper started')
    CdsUtilHelper.cache_delete_all
    start_job(t_id) if t_id != 0
    cid = args[:cid] || -1
    gid = args[:gid] || -1
    pid = args[:pid] || -1
    mid = args[:mid] || -1
    # ss = Snapshot.where(company_id: cid).last
    # sid = ss.try(:id) || -1
    sid = args[:sid] || -1

    sid = Snapshot.where(company_id: cid).last.id if sid == '-1'

    if !args[:rewrite] || args[:rewrite] == 'false'
      rewrite = false
    else
      rewrite = true
    end

    if !args[:calc_all] || args[:calc_all] == 'true'
      calc_all = true
    else
      calc_all = false
    end

    if false
      if Company.find(cid).questionnaire_only?
        PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_scores_for_generic_networks(cid.to_i, sid.to_i, gid.to_i)
      else
        PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_scores(cid.to_i, gid.to_i, pid.to_i, mid.to_i, sid.to_i, rewrite)
      end
    end

    if true
      #[127,128,129,132,133,134,135,136].each do |sid|
      [145].each do |sid|
        [800, 801, 802, 803, 804, 805, 806, 807, 700,701,702,703,704,705,706,707,709,200,201,203,204,205,206,207].each do |aid|
        #[200,201,203,204,205,206,207].each do |aid|
          puts "========================> sid: #{sid}, aid: #{aid}"
          PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_scores(11, -1, -1, aid, sid, true)
        end
        PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_gauges(11, sid, true)
        PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_measures(11, sid, true)
      end
    end

    if false
      ActiveRecord::Base.transaction do
        begin
          if calc_all
            PrecalculateMetricScoresForCustomDataSystemHelper::iterate_over_snapshots(cid, sid) do |compid, snapid|
              PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_gauges(compid.to_i, snapid.to_i, true)
              PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_measures(compid.to_i, snapid.to_i, true)
            end
          end

          finish_job(t_id) if t_id != 0
          EventLog.log_event(job_id: t_id, message: 'precalculate_metric_scores_for_custom_data_system_helper ended')
        rescue => e
          puts "EXCPTION in precalculate_metric_scores_for_custom_data_system: #{e.message[0..1000]}"
          puts e.backtrace
          finish_job_with_error(t_id) if t_id != 0
          status = error
          raise ActiveRecord::Rollback
        end
      end
    end

    EventLog.log_event(job_id: t_id, message: 'precalculate_metric_scores_for_custom_data_system_helper error') if status == error
  end
end
