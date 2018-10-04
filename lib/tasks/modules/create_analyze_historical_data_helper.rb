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
# spanning both collector and app. Therefore it updates the push_proc table which
# is meant to track progress of the "push" job.
# Push job is a synonym for "Push a bunch of historical data into the system -
# at once".
###############################################################################
module AnalyzeHistoricalDataHelper

  def run(cid)

    puts "Start AnalyzeHistoricalDataHelper job"
    PushProc.last.update(state: :count_snapshots)
    ## Find number of snapshots
    mind = RawDataEntry.select('MIN(date)').where(company_id: 1, processed: false)[0][:min]
    maxd = RawDataEntry.select('MAX(date)').where(company_id: 1, processed: false)[0][:max]

    if maxd.nil?
      puts "No data in raw_data_entries, aborting."
    PushProc.last.update(state: :done)
      return
    end

    num_of_weeks = ((maxd - mind) / 1.week).round(0)
    puts "There are about #{num_of_weeks} snapshots in the data"
    PushProc.last.update(num_snapshots: num_of_weeks)


    ## Create snapshots
    PushProc.update(state: :create_snapshots)
    snapshots_arr = []
    (0..(num_of_weeks + 1)).each do |i|
      date = mind + i.weeks
      snapshot = CreateSnapshotHelper::create_company_snapshot_by_weeks(cid, date.to_s, true)
      next if snapshot.nil?
      snapshots_arr.push(snapshot)
      puts "#################################################################"
      puts "Create snapshot of week of the: #{date}, sid: #{snapshot.id}"
      puts "#################################################################"
      PushProc.last.update(num_snapshots_created: PushProc.last.num_snapshots_created + 1)
    end

    ## precalculate snapshots
    PushProc.last.update(state: :preprocess_snapshots)
    ii = 0
    snapshots_arr.each do |snapshot|
      sid = snapshot.id
      ii += 1
      puts "#################################################################"
      puts "Working on snapshot: #{sid}. #{ii} out of #{snapshots_arr.size}"
      puts "#################################################################"
      PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_scores(cid, -1, -1, -1, sid, true)
      #PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_gauges(cid, sid, true)
      #PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_z_scores_for_measures(cid, sid, true)
      PushProc.last.update(num_snapshots_processed: ii)
    end

    puts "Done with AnalyzeHistoricalDataHelper job"
    PushProc.last.update(state: :done)
  end
end
