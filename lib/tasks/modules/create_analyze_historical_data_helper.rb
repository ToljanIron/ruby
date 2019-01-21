require './lib/tasks/modules/precalculate_metric_scores_for_custom_data_system_helper.rb'
require './lib/tasks/modules/create_snapshot_helper.rb'
include PrecalculateMetricScoresForCustomDataSystemHelper
include CreateSnapshotHelper

###############################################################################
# This helper should be used when a bunch of historical data has been pushed
# into the system (raw_data_entries) and should be turned at onec into snapshots
# and should run precalc on all of them.
#
# It is meant to run as a stand alone job which may be part of a bigger proccess
# spanning both collector and app. Therefore it updates the Job and JobStage
# tables. The logic is like this:
#
# A Job describes something at a system level, in this case collecting several
# months worth of historical data of emails and meetings. This helper runs all
# of the create_snapshot and precalculate operations that stem from this data.
# The job and job_stages hierarchy is like this: (where the first one is an
# entry in jobs table and the rest are job_stages)
#
# - collection
#   - collect-history-create-snapshot
#     - collect-history-create-snapshot-1
#       ...
#     - collect-history-create-snapshot-N
#   - collect-history-precalculate
#     - collect-history-precalculate-1
#       ...
#     - collect-history-precalculate-M
#
# The reason create_snapshots go from 1 to N and precaluculates to M is that N
# can be bigger than M if some snapshots turn out to be empty.
#
###############################################################################
module AnalyzeHistoricalDataHelper

  def run(cid)
    puts "Start AnalyzeHistoricalDataHelper job"

    job = Job.where(company_id: cid)
             .where("domain_id like '%collection-historical%'")
             .last
    job.retry if job.status == 'wait_for_retry'
    stage = job.get_next_stage


    main_create_snapshot_stage = nil
    main_precalculate_stage    = nil

    ## Check if already created sub-snapshot stages and proceed from there
    if (stage.domain_id == 'collect-history-create-snapshot')
      main_create_snapshot_stage = stage
      main_create_snapshot_stage.start
      add_create_snapshot_stages(main_create_snapshot_stage)
      stage = job.get_next_stage
    end

    ## Get the main create_snapshot stage and continue with the create_snapshot
    ## stages
    if (stage.stage_type == 'create_snapshot')
      next_stage = stage
      main_create_snapshot_stage = JobStage.where(domain_id: 'collect-history-create-snapshot')
                                           .last
      next_stage = run_create_snapshot_stages(next_stage)
      main_create_snapshot_stage.finish_succesfully("snapshots created")
      stage = next_stage
    end

    ## Check if already created sub-precalc stages and proceed from there
    if (stage.domain_id == 'collect-history-precalculate')
      main_precalculate_stage = stage
      main_precalculate_stage.start
      stage = job.get_next_stage
    end

    ## Get the main precalculate stage and continue with precalculate stages.
    ## Otherwise this is an unexpected situation
    if (stage.stage_type == 'precalculate')
      puts "Start precalculate"
      main_precalculate_stage = JobStage.where(domain_id: 'collect-history-precalculate').last if main_precalculate_stage.nil?
      run_precalculate_stages(job, stage)
      main_precalculate_stage.finish_successfully
    else
      msg = "Unexpected stage: #{stage.id}, domain_id: #{stage.domain_id}, type: #{stage.stage_type}"
      job.finish_with_error(msg)
      raise msg
    end

    puts "Done with AnalyzeHistoricalDataHelper job"
    job.finish_successfully
  end

  #############################################################################
  # Go over all precalculate stages one by one.
  #############################################################################
  def run_precalculate_stages(job, stage)
    ii = 0
    num_stages = JobStage.where(stage_type: 'precalculate', status: ready).count
    next_stage = stage
    while (next_stage.stage_type == 'precalculate') do
      next_stage.start
      sid = next_stage.value

      ii += 1
      puts "#################################################################"
      puts "In precalculate of snapshot: #{sid}. #{ii} out of #{num_stages}"
      puts "#################################################################"
      PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_scores(cid, -1, -1, -1, sid, true)
      PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_gauges(cid, sid, true)
      PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_measures(cid, sid, true)
      next_stage.finish_successfully
    end
  end

  #############################################################################
  # Add create_snapshot job_stages for each week.
  #############################################################################
  def add_create_snapshot_stages(stage)
    ## Find number of snapshots
    mind = RawDataEntry.select('MIN(date)').where(company_id: 1, processed: false)[0][:min]
    maxd = RawDataEntry.select('MAX(date)').where(company_id: 1, processed: false)[0][:max]

    if maxd.nil?
      puts "No data in raw_data_entries, aborting."
      stage.finish_successfully('Nothing to do')
      return
    end

    ## Count approximate number of snapshots and create a job_stage for each one
    num_of_weeks = ((maxd - mind) / 1.week).round(0)
    puts "There are about #{num_of_weeks} snapshots in the data"
    (0..(num_of_weeks + 1)).each do |i|
      date = (mind + i.weeks).to_s
      domain_id = "collect-history-create-snapshot-#{i}"
      next if JobStage.where(domain_id: domain_id).count > 0
      Job.create_stage(domain_id,
                       stage_type: stage.stage_type,
                       value: date,
                       stage_order: stage.stage_order + 1)
    end
  end

  #############################################################################
  # Create snapshots for each stage. When a snapshot is created this function
  # also creates a matching precalculate stage.
  #############################################################################
  def run_create_snapshot_stages(next_stage)
    ## Create snapshots
    #######snapshots_arr = []
    while (next_stage.stage_type == 'create_snapshot') do
      next_stage.start
      date = next_stage.value
      snapshot = CreateSnapshotHelper::create_company_snapshot_by_weeks(cid, date.to_s, true)
      if snapshot.nil?
        next_stage.finish_successfully('Nothing to do')
        next
      end
      ########### snapshots_arr.push(snapshot)
      sid = snapshot.id
      puts "#################################################################"
      puts "Create snapshot of week of the: #{date}, sid: #{sid}"
      puts "#################################################################"
      Job.create_stage("collect-history-precalculate-#{sid}",
                       stage_type: precalculate,
                       value: snp.sid,
                       stage_order: 1000 + 1)
      next_stage.finish_successfully("Snapshot: #{sid}")
      next_stage = job.get_next_stage
    end
  end
end
