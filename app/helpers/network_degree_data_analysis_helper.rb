require 'csv'
require 'roo'
require './app/helpers/xls_helper.rb'

include XlsHelper

	######################################################################################
  # IMPORTANT: Fix functionality - script should take interval instead of specific number in
  # network_sorting_value, and then try and add records if not enough
	# 
  # Description:
  # This script seeks highest values in the degree column, in a subset filtered before by the network
  # column. Analysis steps:
  #   1) Take a subset of the records with a segment (loops over the segments list)
  #   2) Sort this from in ASC/DESC order - depending on whether the network sorting value is
  #      1 or not 
  #      If 1 - will be sorted in ascending order
  #      Else - will be sorted in descending order
  #   3) Extract 2nd subset of employees by defined percentage (defined in script as 
  #      'min_percentage_in_network_subset') - this step will extract employees that have the network
  #      value 'network_value' (i.e. if network_value=1, script will extract employees with 1 as
  #      the network value). If the extracted subset is less than the 'min_percentage_in_network_subset',
  #      the script will add employees closest in value to 'network_value' - from above/below, 
  #      depending on whether the list is sorted in ASC/DESC order (see 2). Note that, if there 
  #      are less than a absolute allowed minimum, defined by 'min_allowed_emp_count' - the script 
  #      will add up to this value and not the percentage value.
  #   4) Out of the 2nd subset - extract employees with highest 'degree' values. Percentage of how many to
  #      extract is defined by 'required_top_percentage'.
  #      This subset is the end result that is written to an excel sheet - for all segments.
  #
  # Script parameters 
  # (passed to init() method)
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
  # network_sorting_value - 
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
  
module NetworkDegreeDataAnalysisHelper

	# Write to this file
	@res_file_name = 'network_analysis_res.xls'

	# The minimum percentage of employees to select from segment
	# with some value in network
	@min_percentage_in_network_subset = 0.1

	# If 10% is less than this number, take this much employees
	@min_allowed_emp_count = 10

	# This is used to take to top scores - stars, champions etc.
	@required_top_percentage = 0.2

	@min_record_count_by_degree = 2

	@debug = false

	@filter_index = 4

	def init(segments_file, data_file, network, degree, network_sorting_value, debug)
		@debug = debug
		segments_arr = get_items_from_file(segments_file)
		
		log("Segments: #{segments_arr}", true)
		
		data_csv = parse_data_file(data_file)

		analyze(segments_arr, data_csv, network, degree, network_sorting_value)
	end

	def get_items_from_file(file_name)
		
		items = []
		
		path = "#{Rails.root}/#{file_name}"
		
		list = File.read(path)

		csv_list = CSV.parse(list)
		
		csv_list.each do |r|
			items << r[0]
		end
		return items
	end

	def parse_data_file(file_name)
		path = "#{Rails.root}/#{file_name}"

		data_sheet = Roo::Excelx.new(path)

		data_csv = CSV.parse(data_sheet.to_csv)

		return data_csv
	end

	def analyze(segments, data, metric, degree, metric_sorting_value)
		
		log("data headers: #{data[0]}", true)

		metric_column = data[0].find_index(metric)
		log("Analyzing by metric: #{metric}. Column number of metric is: #{metric_column}", true)
		log("Sorting value for metric: #{metric_sorting_value}", true)
		
		degree_column = data[0].find_index(degree)
		log("Analyzing by degree: #{degree}. Column number of degree is: #{degree_column}", true)

		segments_mock = ['#10 სერვის ცენტრი']

		res = []

		segments.each do |segment|

			puts "Running analysis for segment: #{segment}"
			emp_segment = get_relevant_employees(@filter_index, segment, data)
			next if emp_segment.nil? || emp_segment.count === 0

			log("Total number of records in #{segment} segment: #{emp_segment.count}", true)
			
			sort_direction = metric_sorting_value === 1 ? "ASC" : "DESC"
			sorted = get_sorted_csv(metric_column, emp_segment, sort_direction)

			records = filter_records_by_metric(metric_column, metric_sorting_value, sorted)

			log_arr("Extracted records by metric:", records)

			sorted_by_score = get_sorted_csv(degree_column, records, "ASC")

			# Take top percentage
			top_scores = get_top_percentage(@required_top_percentage, sorted_by_score, degree_column)

			log("Number of records after taking #{@required_top_percentage*100}%: #{top_scores.count}")
			
			res += format_for_write(top_scores, degree, metric, metric_column, degree_column)
		end

		log("Analyzed #{segments.count} segments")

		write_results_to_file(res, @res_file_name)
	end

	def get_relevant_employees(column_index, filter_name, data)
		res = []

		data.each do |d|
			res << d if (d[column_index] === filter_name)
		end
		return res
	end

	def get_sorted_csv(column_index, data, direction)
		log("sorting segment in #{direction} order, by index: #{column_index}.", true)

		if(direction == "ASC")
			res = data.sort_by{|d| d[column_index].to_f}.reverse!
		else
			res = data.sort_by{|d| d[column_index].to_f}
		end
		
		return res
	end

	def filter_records_by_metric(column_index, column_value, segment_csv)
		
		total_count = segment_csv.count
		min_emp_count = (total_count * @min_percentage_in_network_subset).ceil		
		log("Initial employee count requirement by percentage (#{@min_percentage_in_network_subset*100}%): #{min_emp_count} employees", true)

		relevant_records = segment_csv.find_all {|row| (row[column_index].to_f - column_value).abs < 0.001 }
		
		# Michael K. - 17.9.17 - This is to take interval instead of specific value. But, when using this, comment out the
		# the loop where it adds more employees if not enough, because it wont work properly. Need to fix this
		# relevant_records = segment_csv.find_all {|row| row[column_index].to_f >= -1 && row[column_index].to_f <= -0.4 }

		relevant_records_count = relevant_records.count
		
		log_arr("Relevant records - where column value is: #{column_value} (by column number: #{column_index})", relevant_records)
		
		number_of_records_to_add = 0

		max = [min_emp_count, @min_allowed_emp_count].max

		if(relevant_records_count < max)
			number_of_records_to_add = max - relevant_records_count
		end

		log("I have enough employees") if (number_of_records_to_add === 0)

		if (number_of_records_to_add != 0)

			log("Not enough employees - trying to add #{number_of_records_to_add} more")

			# Find index of first record that is different from 'column_value'
			index_of_first_different = find_index_of_last_value(column_index, column_value, segment_csv)
			
			log("index_of_first_different ? #{index_of_first_different}")
			
			high_degree = column_value === 1
			# Add number of needed records to 'relevant_records'
			for i in index_of_first_different..(index_of_first_different + number_of_records_to_add - 1)
   			
   			if (i >= total_count)
   				log("No more employees in group to add. Stopping!", true)
   				break
   			end

   			if((segment_csv[i][column_index].to_f < 0.5 && high_degree) || (segment_csv[i][column_index].to_f > 0.7 && !high_degree))
   				log("Wanted to add record, but it has #{high_degree ? 'lower' : 'higher'} value than 0.5. Record is\n#{segment_csv[i]}")
   				log("Stopping addition of records")
   				break
   			end

   			log("Adding record: #{segment_csv[i]}")
   			relevant_records << segment_csv[i]
			end
		end

		return relevant_records
	end

	def get_top_percentage(percentage, data, degree_index)
		res = []
		
		required_num_of_records = (data.count * percentage).ceil

		if(required_num_of_records < @min_record_count_by_degree && data.count >= @min_record_count_by_degree)
			# Take at least 2 records for final results
			required_num_of_records = @min_record_count_by_degree
		end

		required_num_of_records.times do |i|
			res << data[i]

			if (i === required_num_of_records - 1)				
		  	degree_of_last = data[i][degree_index].to_i
				j = i + 1
		  	while (j < data.count && degree_of_last != 0 && degree_of_last === data[j][degree_index].to_i) do
		  		log("** Found record with the same indegree, beyond the required number of records. Adding also to top records.\nRecord is:\n#{data[j]}")
		  		res << data[j]
		  		j += 1
		  	end
		  end
		end
		return res
	end

	# Find the index of the first record that is different from the 
	# value in the given column index. Data must be sorted by this value
	def find_index_of_last_value(column_index, value, data)
		index_of_last = -1

		data.each_with_index do |d, i|		
			if(d[column_index].to_s != value.to_s)
				index_of_last = i
				break
			end
		end
		return index_of_last
	end

	def format_for_write(data, score_string, sorting_string, sorting_index, degree_column)

		arr = []

		arr << ['Group', 'ext id', 'Name', score_string, sorting_string]

		data.each do |d|
			arr << [d[@filter_index], d[0], d[1], d[degree_column], d[sorting_index].to_f.round(2)]
		end

		# Add separator
		arr << ['------------', '------------', '------------------------------------', '------------', '------------']
		# arr.each {|a| puts "#{a}"}
		return arr
	end

	def write_results_to_file(data, file_name)
		log("writing to file: #{file_name}")
		
		workbook = XlsHelper.create_file_2(file_name)

		worksheet  = workbook.add_worksheet

    data.each_with_index do |row_data, i|
      row_data.each_with_index do |column_data, j|
      	# puts "(i,j) = (#{i},#{j})"
        worksheet.write(i, j, column_data)
      end
    end
    
    workbook.close
	end

	def log(text, force_debug = false)
		if (@debug || force_debug)
			puts text
			puts "----------------------------"
		end
	end

	def log_arr(header, array, force_debug = false)
		if (@debug || force_debug)
			puts header
			array.each {|a| puts "#{a}"}
			puts "Count is: #{array.count}"
			puts "----------------------------"
		end
	end
end