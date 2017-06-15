require './app/helpers/util_helper.rb'
require './app/helpers/dashboard_helper.rb'
include DashboardHelper
include UtilHelper
DIFFRENCE_DYAD = 'Difference dyad'.freeze
NO_SNAPSHOT = -1
namespace :db do
  desc 'create_communication_volume'
  task :create_communication_volume, [:cid, :sid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    cid = args[:cid] || ENV['COMPANY_ID'] || (raise 'No company ID given (cid)')
    sid = args[:sid].to_i
    sid = NO_SNAPSHOT if sid.zero?
    UtilHelper.cache_delete_all
    ActiveRecord::Base.transaction do
      begin
        gid = Group.where(company_id: cid, parent_group_id: nil).first.try(:id)
        raise 'there is no parent group in company' unless gid
        puts "Running with CID=#{cid}, sid=#{sid}, gid=#{gid}"
        cache_key = "dyads_with_the_biggest_diff-#{cid}-#{gid}-#{sid}"
        communication_volumes = DashboardHelper.most_communication_volumes_diff_between_dayds(gid, sid)
        most_communication_volumes = communication_volumes.take(5)
        data = DashboardHelper.create_json_structure(most_communication_volumes, DIFFRENCE_DYAD)
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
