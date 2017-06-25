require 'line_processing_context.rb'
require 'csv'

module ImportDataHelper
  #
  # accepts the company_id of the company in question
  # and a csv string with lines describing company
  # structure, personal info or management structure
  #
  # creates and/or connects the objects in the database
  #
  # returns an array of string error messages
  #
  EMPLOYEES_CSV  = 1
  MANAGMENT_RELATION_CSV = 3
  NETWORK        = 4
  EMAILS         = 5
  GROUPS_CSV     = 6

  CSV_NAMES = [
    'NA',
    'Employees',
    'NA',
    'Management',
    'Network',
    'Emails',
    'Groups'
  ]

  CSV_TYPES = {
    employee_csv: EMPLOYEES_CSV,
    managment_relation_csv: MANAGMENT_RELATION_CSV,
    trust: NETWORK,
    emails: EMAILS,
    groups_csv: GROUPS_CSV
  }

  VALID_GROUP_CSV_LINE_SIZE      = 5
  VALID_MANAGMENT_RELATION_CSV_LINE_SIZE = 4
  VALID_EMPLOYEE_CSV_LINE_SIZE   = 20
  VALID_NETWORK_CSV_LINE_SIZE    = 4
  VALID_EMAILS_CSV_LINE_SIZE     = 20


  def push_errors(errors, company_id, file, network, csv_type, use_latest_snapshot=false, date_format = nil)
    errors.push '-' * 50 + "\n#{network.name}:\n"        if csv_type == NETWORK
    errors.push '-' * 50 + "\n#{CSV_NAMES[csv_type]}:\n" if csv_type != NETWORK

    errors.push ImportDataHelper.import_data_from_csv_to_db(company_id, file.read, network, csv_type, use_latest_snapshot, date_format) if file
  end

  def import_data_from_csv_to_db(company_id, csv, network, csv_type, use_latest_snapshot=false, date_format)
    raise 'csv_types 2 (old groups) and 5 (emails) are no longer supported' if [2,5].include?(csv_type)
    return 'import_company_data_from_csv: unknown csv type' if ![1,3,4,6].include?(csv_type)
    csv_headline = csv.split("\n")[0]
    csv_headline = csv_headline.strip
    line_size_res = check_line_size(csv_headline, csv_type)
    return line_size_res if line_size_res != ''
    correct_names = check_correct_names(csv_headline, csv_type)
    return correct_names unless correct_names == ''
    csv = prepare_for_csv_parsing(csv)
    context_list = lift_csv_to_context_list(company_id, csv, network, csv_type, use_latest_snapshot, date_format)
    context_list.each do |co|
      if co.attrs[:delete]
        co.delete
      else
        co.create_if_not_existing
        co.connect
      end
    end
    return context_list_errors(context_list)
  end

  def self.export_csv_with_external_id(csv_path, question_type)
    src = []
    CSV.foreach(csv_path, :headers => false) do |row|
      src.push(row)
    end
    create_headers(src, question_type)
    formatted_questions = get_ans_formatted(csv_path, src)
    write_question_to_csv(formatted_questions, question_type)
  end

  def self.write_question_to_csv(formatted_questions, question_type)
    csv_file = CSV.open("#{question_type}" + '.csv', 'a+')
    formatted_questions.each do |row|
      csv_file << row
    end
    csv_file.close
  end

  def self.get_ans_formatted(csv_path, src)
    ans = []
    start_of_lines = 1
    end_of_lines = CSV.readlines(csv_path).size - 1
    (start_of_lines..end_of_lines).each_with_index do |row, index|
      external_id = get_external_id_by_email(src[row][0])
      referred_external_id = get_external_id_by_email(src[row][1])
      ans << [external_id, referred_external_id, src[row][2], src[row][3]]
    end
    return ans
  end

  def self.get_external_id_by_email(email)
    return Employee.find_by(email: email).external_id
  end

  def self.create_headers(src, question_type)
    csv_target = CSV.open("#{question_type}" + '.csv', 'w')
    csv_target << [src[0][0], src[0][1], src[0][2], src[0][3]]
    csv_target.close
  end

  ######################### Imange upload #########################################
  IMAGES_FILE_NAME='/home/dev/Development/workships/public/employee_images.zip'
  def upload_images(cid, images_file)
    puts "Saving uploaded employees zip file for company: #{cid}"
    File.open(IMAGES_FILE_NAME, "wb") { |f| f.write(images_file.read) }
    puts "Done"
  end

  ######################### Import Excel  #########################################

  def load_excel_sheet(cid, spreadsheet)
    ex = Roo::Excelx.new(spreadsheet.path)

    emps_sht = ex.sheet('Employees')
    context_list = lift_excel_to_context_list(cid, emps_sht, 'emps')

    groups_sht = ex.sheet('Groups')
    groups_context_list = lift_excel_to_context_list(cid, groups_sht, 'groups')


    context_list += groups_context_list
    ## This is not a mistake. It's done in order to make sure all group parent groups are accounted for
    context_list += groups_context_list

    ii = 0
    context_list.each do |co|
      ii += 1
      puts "Woring on context number: #{ii}" if (ii % 50 == 0)
      if co.attrs[:delete]
        co.delete
      else
        co.create_if_not_existing
        co.connect
      end
    end
    return context_list_errors(context_list)
  end

  def lift_excel_to_context_list(cid, xls, sht_type)
    context_list = xls.each_with_index.map do |xls_line, xls_line_number|
      ret = nil
      if xls_line_number > 0
        ret = process_xls_employee(xls_line, cid, xls_line, xls_line_number) if sht_type == 'emps'
        ret = process_xls_groups(xls_line, cid, xls_line, xls_line_number) if sht_type == 'groups'
      end
      ret
    end
    ret = context_list.flatten
    ret = ret.select { |e| !e.nil? }
    ret.delete_at(0)
    return ret
  end

  def parse_date_for_xls(d)
    return nil if d.nil?
    return nil if d.class == String
    return d.strftime("%Y-%m-%d")
  end

  def process_xls_employee(parsed, company_id, csv_line, csv_line_number)
    puts "ERROR: Line size: #{parsed.length} is incorrect for line number: #{csv_line_number}, will proceed anyway." unless parsed.length == VALID_EMPLOYEE_CSV_LINE_SIZE

    employee_context = EmployeeLineProcessingContext.new(csv_line, csv_line_number, company_id)
    email = parsed[4]
    return nil if (email.nil?)
	begin
	    employee_context.attrs.merge!(
	      company_id:       company_id,
	      external_id:      format_string(parsed[0]),
	      first_name:       safe_titleize(parsed[1]),
	      middle_name:      safe_titleize(parsed[2]),
	      last_name:        safe_titleize(parsed[3]),
	      email:            format_string(email),
	      #alias_email:      format_string(parsed[5]),
	      role:             format_string(parsed[6]),
	      rank:             parsed[7],
	      job_title:        format_string(parsed[8]),
	      date_of_birth:    parse_date_for_xls(parsed[9]),
	      gender:           format_string(parsed[10]),
	      marital_status:   format_string(parsed[11]),
	      work_start_date:  parse_date_for_xls(parsed[12]),
	      qualifications:   format_string(parsed[13]),
	      home_address:     format_string(parsed[14]),
	      office_address:   format_string(parsed[15]),
	      position_scope:   parsed[16].class == Fixnum ? parsed[16] : parsed[16].strip,
	      group_name:       safe_titleize(parsed[17]),
	      id_number:        format_string(parsed[18]),
	      delete:           is_delete?(parsed[19])
	    )
	rescue => e
	  puts "Exception loading employee with email: #{email} with error: #{e.message}"
	  raise e.message
	end
    return [employee_context]
  end

  def process_xls_groups(parsed, company_id, csv_line, csv_line_number)
    date = parsed[4] || Time.now
    date = date.strftime('%Y-%m-%d')
    name = safe_titleize(parsed[1].strip)
    english_name = safe_titleize(parsed[5].strip)
    group_context = GroupLineProcessingContext.new(csv_line, csv_line_number, company_id)
    group_context.attrs.merge!(
      company_id: company_id,
      external_id: parsed[0].nil? ? name : parsed[0], ## If external_id is not provided then default to the name
      name: name,
      parent_external_id: parsed[2],
      delete: parsed[3].nil? ? false : !parsed[3].empty?,
      date: date,
      english_name: english_name
    )
    return [group_context]
  end


  def format_string(s)
    return nil if s.nil? || s.empty?
    s = s.strip
    return nil if s.empty?
    return s.strip.downcase
  end
  #################################################################################

  private

  include LineProcessingContextClasses

  def check_correct_names(csv_headline, csv_type)
    expected_headings = csv_headings(csv_type) #array of headings
    actual_headings = csv_headline.split(',')
    str = ''
    for i in 0..expected_headings.length
      next if expected_headings[i].nil?
      if expected_headings[i].strip != actual_headings[i].strip
        str += "Field #{i} is >>>#{actual_headings[i].strip}<<< instead of >>>#{expected_headings[i].strip}<<<.\n "
      end
    end
    return str
  end

  def csv_headings(csv_type)
    case csv_type
    when EMPLOYEES_CSV #1
      return ['external_id', 'first_name', 'middle_name', 'last_name', 'email',
              'alias_emails', 'role', 'rank', 'job_title', 'date_of_birth',
              'gender', 'marital_status', 'work_start_date', 'qualifications', 'home_address',
              'office_address', 'position_scope', 'group_name', 'id_number', 'delete'
              ]
    when MANAGMENT_RELATION_CSV #3
      return ["manager_external_id", "employee_external_id", "relation_type", "delete"]
    when NETWORK  #ASAF BYEBUG just add here?
      return ["from_employee_id", "to_employee_id", "value", "snapshot"]
    when GROUPS_CSV
      return ['exteral_id','group_name','parent_group_external_id','delete','group_update_date']
    end
  end

  def check_line_size(csv_headline, csv_type)
    expected_size = expected_line_size(csv_type)
    actual_size   = csv_headline.split(",").size
    return '' if actual_size == expected_size
    return "Number of columns is incorrect. Expected: #{expected_size}, actual: #{actual_size}\nHeadings found: #{csv_headline.split(",")}"
  end

  def expected_line_size(csv_type)
    case csv_type
      when EMPLOYEES_CSV
        return VALID_EMPLOYEE_CSV_LINE_SIZE
      when GROUPS_CSV
        return VALID_GROUP_CSV_LINE_SIZE
      when MANAGMENT_RELATION_CSV
        return VALID_MANAGMENT_RELATION_CSV_LINE_SIZE
      when NETWORK
        return VALID_NETWORK_CSV_LINE_SIZE
    end
  end

  def prepare_for_csv_parsing(csv)
    return nil unless csv
    csv = csv.split("\n")[1..-1].join("\n")
    return csv
  end

  def is_delete?(parsed)
    return false if (parsed.nil? || parsed[18].nil?)
    return !parsed[18].empty?
  end

  def safe_titleize(str)
    return nil if str.nil?
    return str.titleize if !str.match(/^[a-zA-Z \-]*$/).nil?
    return str
  end

  def process_groups(parsed, company_id, csv_line, csv_line_number)
    date = Time.now.strftime('%Y-%m-%d')
    if parsed[4].nil?
      date_formatter(parsed[4].strip, date_format_id)
    end
    name = safe_titleize(parsed[1].strip)
    group_context = GroupLineProcessingContextNew.new(csv_line, csv_line_number, company_id)
    group_context.attrs.merge!(
      company_id: company_id,
      external_id: parsed[0].nil? ? name : parsed[0], ## If external_id is not provided then default to the name
      name: name,
      parent_external_id: parsed[2],
      delete: parsed[3].nil? ? false : !parsed[3].empty?,
      date: date
    )
    return [group_context]
  end

  def process_employee_relation(parsed, company_id, csv_line, csv_line_number)
    employee_context = RelationLineProcessingContext.new(csv_line, csv_line_number, company_id)
    employee_context.attrs.merge!(
      manager_external_id:   parsed[0].strip,
      employee_external_id:  parsed[1].strip,
      relation_type:         parsed[2].strip,
      delete:               !parsed[3].empty?,
      version:              'v1'
    )
    return [employee_context]
  end

  def process_csv_network(parsed, company_id, csv_line, csv_line_number, csv_type, use_latest_snapshot=false)
    return [ErrorLineProcessingContext.new(csv_line, csv_line_number, company_id, csv_type)] unless parsed.length == VALID_NETWORK_CSV_LINE_SIZE
    csv_network_context = NetworkLineProcessingContext.new(csv_line, csv_line_number, company_id, csv_type, use_latest_snapshot)
    csv_network_context.attrs.merge!(
      from_employee_id:    parsed[0].strip,
      to_employee_id:      parsed[1].strip,
      value:               parsed[2].strip,
      snapshot:            parsed[3].strip,
      csv_type:            csv_type.name,
      version:             'v2',
      use_latest_snapshot: use_latest_snapshot
    )
    return [csv_network_context]
  end

  ########################################## lift Methods ##########################################

  def lift_csv_to_context_list(company_id, csv, network, csv_type, use_latest_snapshot=false, date_format = nil)
    context_list = csv.split("\n").each_with_index.map do |csv_line, csv_line_number|
      lift_csv_line_to_context_list(company_id, csv_line, csv_line_number + 1, network, csv_type, use_latest_snapshot, date_format)
    end
    return context_list.flatten
  end

  def lift_csv_line_to_context_list(company_id, csv_line, csv_line_number, network, csv_type, use_latest_snapshot, date_format)
    csv_line.force_encoding('UTF-8')
    line = csv_line.gsub("'", "\"")

    parsed = CSV.parse(line).flatten
    parsed = parsed.map { |elem| elem.nil? ? '' :  elem  }

    return process_employee(parsed, company_id, csv_line, csv_line_number, date_format)                           if (csv_type == EMPLOYEES_CSV)
    return process_groups(parsed, company_id, csv_line, csv_line_number)                                          if (csv_type == GROUPS_CSV)
    return process_employee_relation(parsed, company_id, csv_line, csv_line_number)                               if (csv_type == MANAGMENT_RELATION_CSV)
    return process_csv_email_network(parsed, company_id, csv_line, csv_line_number, network, use_latest_snapshot) if (csv_type == EMAILS)
    return process_csv_network(parsed, company_id, csv_line, csv_line_number, network, use_latest_snapshot)       if (csv_type == NETWORK)

    return [ErrorLineProcessingContext.new(csv_line, csv_line_number, company_id)]
  end

  ############################## Utility Methods #######################################

  def date_formatter(date, date_format_id)
    date_format_id ||= '2'
    case date_format_id
    when '1'
      delimitter = '-'
      year  = 0
      month = 1
      day   = 2

    when '2'
      delimitter = '/'
      year  = 2
      month = 1
      day   = 0
    end
    toks = date.split(delimitter)
    toks = handle_year_at_end_of_string(toks[year], toks[month], toks[day])
    res = "#{toks[year]}-#{toks[month]}-#{toks[day]}"
    return res
  end

  def handle_year_at_end_of_string(year, month, day)
    return [day, month, year] if day.to_i > 1000
    return [year, month, day]
  end
end
