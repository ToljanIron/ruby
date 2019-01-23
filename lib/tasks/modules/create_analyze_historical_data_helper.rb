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
# The flow is a little tricky because it's intended to handle retries. This means
# that if it was run and was stopped at any time, it should know to procedd from
# the stage where it has strated. That is the reason for the 4 "if" statements -
# these if's check to see at which stage to commence the flow.
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
    puts "1 >>> stage: #{stage.domain_id}"
    if (stage.domain_id == 'collect-history-create-snapshot')
      main_create_snapshot_stage = stage
      main_create_snapshot_stage.start
      add_create_snapshot_stages(job, main_create_snapshot_stage)
      stage = job.get_next_stage
    end

    ap JobStage.select(:domain_id, :stage_type, :stage_order).order(:stage_order)


    ## Get the main create_snapshot stage and continue with the create_snapshot
    ## stages
    puts "2 >>> stage: #{stage.domain_id}"
    if (stage.stage_type == 'create_snapshot')
      next_stage = stage
      main_create_snapshot_stage = JobStage.where(domain_id: 'collect-history-create-snapshot')
                                           .last
      next_stage = run_create_snapshot_stages(job, next_stage, cid)
      main_create_snapshot_stage.finish_successfully("snapshots created")
      stage = next_stage
    end

    ## Check if already created sub-precalc stages and proceed from there
    puts "3 >>> stage: #{stage.domain_id}"
    if (stage.domain_id == 'collect-history-precalculate')
      main_precalculate_stage = stage
      main_precalculate_stage.start
      stage = job.get_next_stage
    end

    ## Get the main precalculate stage and continue with precalculate stages.
    ## Otherwise this is an unexpected situation
    puts "4 >>> stage: #{stage.domain_id}"
    if (stage.stage_type == 'precalculate')
      puts "Start precalculate"
      main_precalculate_stage = JobStage.where(domain_id: 'collect-history-precalculate').last if main_precalculate_stage.nil?
      run_precalculate_stages(job, stage, cid)
      main_precalculate_stage.finish_successfully
    else
      msg = "Unexpected stage: id: #{stage.id}, domain_id: #{stage.domain_id}, type: #{stage.stage_type}"
      job.finish_with_error(msg)
      raise msg
    end

    puts "Done with AnalyzeHistoricalDataHelper job"
    job.finish_successfully
  end

  #############################################################################
  # Go over all precalculate stages one by one.
  #############################################################################
  def run_precalculate_stages(job, stage, cid)
    ii = 0
    num_stages = JobStage.where(stage_type: 'precalculate', status: :ready).count
    next_stage = stage
    while (next_stage.try(:stage_type) == 'precalculate') do
      ii += 1
      sid = next_stage.value
      puts "#################################################################"
      puts "In precalculate of snapshot: #{sid}. #{ii} out of #{num_stages}"
      puts "#################################################################"
      next_stage = run_precalculate_stage(job, next_stage, sid, cid)
    end
  end

  def run_precalculate_stage(job, next_stage, sid, cid)
    next_stage.start
    PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_scores(cid, -1, -1, -1, sid, true)
    PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_gauges(cid, sid, true)
    PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_measures(cid, sid, true)
    next_stage.finish_successfully
    return job.get_next_stage
  end

  #############################################################################
  # Add create_snapshot job_stages for each week.
  #############################################################################
  def add_create_snapshot_stages(job, stage)
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
      job.create_stage(domain_id,
                       stage_type: stage.stage_type,
                       value: date,
                       order: stage.stage_order + i + 1)
    end
  end

  #############################################################################
  # Create snapshots for each stage. When a snapshot is created this function
  # also creates a matching precalculate stage.
  #############################################################################
  def run_create_snapshot_stages(job, next_stage, cid)

    ii = 1
    while (next_stage.stage_type == 'create_snapshot') do
      puts "In stage: #{next_stage.domain_id}"
      next_stage.start
      date = next_stage.value
      snapshot = CreateSnapshotHelper::create_company_snapshot_by_weeks(cid, date.to_s, true)
      if snapshot.nil?
        next_stage.finish_successfully('Nothing to do')
        next_stage = job.get_next_stage
        next
      end

      sid = snapshot.id
      puts "#################################################################"
      puts "Create snapshot of week of the: #{date}, sid: #{sid}"
      puts "#################################################################"
      job.create_stage("collect-history-precalculate-#{sid}",
                       stage_type: 'precalculate',
                       value: sid,
                       order: 1000 + ii)
      ii += 1
      next_stage.finish_successfully("Snapshot: #{sid}")
      next_stage = job.get_next_stage
      puts "ii: #{ii}"
    end

    return next_stage
  end
end
