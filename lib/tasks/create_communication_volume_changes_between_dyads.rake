require './app/helpers/util_helper.rb'
require './app/helpers/dashboard_helper.rb'
include DashboardHelper
include UtilHelper
namespace :db do
  desc 'create_communication_volume_changes_between_dyads'
  task :create_communication_volume_changes_between_dyads, [:cid, :type] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    cid = args[:cid] || ENV['COMPANY_ID'] || (raise 'No company ID given (cid)')
    snapshot_2_type = args[:type].to_i
    UtilHelper.cache_delete_all
    ActiveRecord::Base.transaction do
      DIFFRENCE_DYAD = 'Difference dyad'.freeze
      NO_SNAPSHOT = -1
      QUARTELY_CHANGE_DYAD = 'Quarterly change dyad'.freeze
      PLUS_SIGN = '+'.freeze
      begin
        gid = Group.where(company_id: cid, parent_group_id: nil).first.try(:id)
        raise 'there is no parent group in company' unless gid
        s_1_id = Snapshot.where(company_id: cid, snapshot_type: nil).order('timestamp desc').first.try(:id)
        s_2_id = DashboardHelper.fetch_snapshot_from_type(s_1_id, cid, snapshot_2_type)
        puts "Running with CID=#{cid}, s_1_id=#{s_1_id}, s_2_id=#{s_2_id},  gid=#{gid}"
        if s_1_id && s_2_id
          communication_volumes_diff_between_dayds_in_s1 = DashboardHelper.most_communication_volumes_diff_between_dayds(gid, s_1_id, PLUS_SIGN)
          communication_volumes_diff_between_dayds_in_s2 = DashboardHelper.most_communication_volumes_diff_between_dayds(gid, s_2_id, PLUS_SIGN)
          res = DashboardHelper.communication_volumes_diff_between_dayds_in_2_snapshots(communication_volumes_diff_between_dayds_in_s1, communication_volumes_diff_between_dayds_in_s2)
          top_5_communication_volumes = res.take(5)
          data = DashboardHelper.create_json_structure(top_5_communication_volumes, QUARTELY_CHANGE_DYAD, s_1_id, s_2_id)
        else
          data = []
        end
        cache_key = "communication_volume_changes_between_dyads-#{cid}-#{gid}-#{s_1_id}-#{s_2_id}"
        cache_write(cache_key, data)
      rescue => e
        error = e.message
        puts "got exception: #{error}"
        puts e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end