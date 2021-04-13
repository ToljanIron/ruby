namespace :db do
	require './lib/tasks/modules/precalculate_network_metrics_helper.rb'
	include PrecalculateNetworkMetricsHelper

	desc 'precalculate network metrics'
	task :calculate_network_metrics, [:cid,:sid] => :environment do |t, args|
		cid = args[:cid] || -1
		sid = args[:sid] || -1
		Rails.logger.info "Started at #{Time.now}"
		PrecalculateNetworkMetricsHelper::calculate_questionnaire_score(cid.to_i,sid.to_i)
		Rails.logger.info "Finished at #{Time.now}"
	end
end