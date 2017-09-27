require './app/helpers/network_degree_data_analysis_helper.rb'
# include NetworkInDegreeDataAnalysisHelper

namespace :db do
  desc ''
  ######################################################################################
  # Task parameters:
  # 
  # segments_file - 
  # This file contains a list of segments by which the analysis will run. 
  # For example, by departments or offices etc. (no matter what this segment represents, this 
  # should aggregate employees by some logical group - we can define that a segment is people 
  # with black hair - and the analysis will run by)
  # 
  # data_file - 
  # The data to analyze. This file should contain ext_id and name of employee AS COLUMNS 0, 1 
  # respectively. Moreover, it should contain columns named by the network, and degree - names 
  # should be the exact string which is given in the network, and degree params.
  # 
  # network - 
  # The network by which to analysze the data.
  # 
  # network_value - 
  # The value in the network column by which to make the first filter stage. Currently supports
  # only single value - but in the future should be given an interval of values
  # 
  # degree - 
  # The degree on which we make the analysis - currently takes the top values. How many values is
  # determined by group size - some percentage (defined in code), or minimum (defined in code)
  # if there are not enough.
  # 
  # debug - whether to print out to console more elaborate debug messages
  # 
  ######################################################################################
  task :network_analysis, [:segments_file, :data_file, :network, :network_value, :degree, :debug] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    t_id = ENV['ID'].to_i
  
    begin
      segments_file = args[:segments_file]
      data_file = args[:data_file]
      network = args[:network]
      network_sorting_value = args[:network_value].to_i
      degree = args[:degree]
      debug = args[:debug] || false
      
      puts "Starting network_analysis task"

      #NetworkDegreeDataAnalysisHelper.init(segments_file, data_file, network, degree, network_sorting_value, debug)

      finish_job(t_id) if t_id != 0
    # rescue => e
    #   finish_job_with_error(t_id) if t_id != 0
    end
  end
end
