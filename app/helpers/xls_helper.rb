require 'writeexcel'
require 'open-uri'
require 'fastimage'

module XlsHelper
  
  def create_file(file_name)
    file_path = "#{Rails.root}/tmp/#{file_name}"
    workbook  = WriteExcel.new(file_path)
    return workbook
  end

  def create_file_2(file_path)
    full_file_path = "#{Rails.root}/#{file_path}"
    workbook  = WriteExcel.new(full_file_path)
    return workbook
  end

  def write_report_to_sheet(worksheet, employee_ids, group_id, pin_id, formats)
    group_id = nil if group_id == -1
    pin_id = nil if pin_id == -1
    fail 'No employees found' if employee_ids.empty?
    cid = Employee.find(employee_ids[0])[:company_id]
    last_snapshot_id = Snapshot.where(company_id: cid).order('id ASC').last[:id]
    @last_column = 'A'
    @last_row = 1
    employee_ids.each_with_index do |id, index|
      write_employee_details(worksheet, id, index * 13 + 1, formats[:center])
      write_employee_scores(worksheet, id, last_snapshot_id, group_id, pin_id, index * 13 + 1, formats)
    end
    worksheet.print_area("A1:#{@last_column}#{@last_row}")
  end

  def write_employee_details(worksheet, employee_id, row_number, format)
    employee = Employee.find(employee_id)
    employee_division = fetch_division(employee[:group_id]) if employee[:group_id]
    employee_details = { 'First Name' => employee[:first_name],
                         'Last Name' => employee[:last_name],
                         'Age' => 'N/A',
                         'Gender' => employee[:gender] == 1 ? 'F' : 'M',
                         'Seniority' => employee[:rank_id].try(:to_s) || '',
                         'Job Title' => employee[:job_title_id] ? JobTitle.find(employee[:job_title_id]).name : '',
                         'Division' => employee_division,
                         'Department' => Group.find(employee[:group_id]).name,
                         'Location' => employee[:office_id] ? Office.find(employee[:office_id]).name : '' }

    write_employee_image(worksheet, employee[:img_url], row_number)
    worksheet.write("D#{row_number}", 'Details', format)
    worksheet.set_column('C:C', column_width(employee_details.keys))

    employee_details.each_with_index do |detail, idx|
      @details_width = set_column_width(worksheet, 'D', detail[1], @details_width)
      current_row = row_number + idx + 1
      @last_row = current_row if @last_row.nil? || @last_row < current_row
      worksheet.write("C#{current_row}", detail, format)
    end
  end

  def write_employee_image(worksheet, img_url, row_number)
    begin
      img_size = FastImage.size(img_url)
      rate = img_size[0] > 120 || img_size[1] > 120 ? 120.0 / img_size.max : 1
      # extension = img_url.split('.').last.split('?').first
      extension = 'jpg'
      open("#{Rails.root}/tmp/#{worksheet.name}#{row_number}.#{extension}", 'wb') do |file|
        file << open(img_url).read
      end
      worksheet.insert_image("A#{row_number}", "#{Rails.root}/tmp/#{worksheet.name}#{row_number}.#{extension}", 0, 0, rate, rate)
    rescue
      worksheet.write("A#{row_number}", 'No image')
    end
  end

  def write_employee_scores(worksheet, employee_id, snapshot_id, group_id, pin_id, row_number, formats)
    measure_ids = Metric.where(metric_type: 'measure').map(&:id)
    employee_score_rows = MetricScore.where(employee_id: employee_id, group_id: group_id, pin_id: pin_id, snapshot_id: snapshot_id).select { |row| measure_ids.include? row[:metric_id] }

    @metrics_width = [] unless @metrics_width
    dollar_score = dollar_calculate(employee_id, snapshot_id)
    company_id = Snapshot.find(snapshot_id)[:company_id]
    previous_snapshot_id = Snapshot.where(company_id: company_id).order(id: :asc)[-2].try(:id)
    employee_previous_score_rows = MetricScore.where(employee_id: employee_id, group_id: group_id, pin_id: pin_id, snapshot_id: previous_snapshot_id).select { |row| measure_ids.include? row[:metric_id] }
    columns = ('F'..'Z').to_a
    max = 0
    employee_score_rows.each_with_index do |row, i|
      metric_name = Metric.find(row[:metric_id])[:name]
      l = columns[i]
      @last_column = l if @last_column.nil? || @last_column < l
      @metrics_width[i] = set_column_width(worksheet, l, metric_name, @metrics_width[i])
      old_score = employee_previous_score_rows.select { |r| r[:metric_id] == row[:metric_id] }[0].try(:score)
      new_score = row[:score]
      worksheet.write("#{l}#{row_number}", metric_name, formats[:center])
      color = score_color(old_score, new_score)
      format = color ? formats[color.to_sym] : formats[:center]
      worksheet.write("#{l}#{row_number + 1}", new_score, format)
      max = i
    end
    l = columns[max + 1]
    worksheet.write("#{l}#{row_number}", 'Time in seconds', formats[:center])
    worksheet.set_column("#{l}:#{l}", 'Time in seconds'.size)
    worksheet.write("#{l}#{row_number + 1}", dollar_score, formats[:center])
  end

  def score_color(old_score, new_score)
    return nil unless old_score
    if old_score < new_score
      return 'green'
    elsif new_score < old_score
      return 'red'
    end
    return nil
  end

  def fetch_division(group_id)
    group = Group.find(group_id)
    parent_group_id = group[:parent_group_id]
    return '' if parent_group_id.nil?
    parent_group = Group.find(parent_group_id)
    return group[:name] if parent_group[:parent_group_id].nil?
    fetch_division(parent_group_id)
  end

  def set_column_width(worksheet, column, string, current_width)
    if current_width.nil? || string.size > current_width
      worksheet.set_column("#{column}:#{column}", string.size)
      return string.size + 0.3
    else
      worksheet.set_column("#{column}:#{column}", current_width)
      return current_width
    end
  end

  def dollar_calculate(emp_id, sid)
    company = Snapshot.find(sid).company_id
    network = NetworkSnapshotData.emails(company)
    employee_relation = NetworkSnapshotData.where('(snapshot_id = ?) and (network_id = ?) and ((from_employee_id = ?) or (to_employee_id = ? ))', sid, network, emp_id, emp_id)
    return 0 if employee_relation.empty?
    score = employee_relation.length
    return score * Configuration.email_average_time
  end

  def column_width(words)
    words.map(&:size).max
  end

  def self.export_employee_attributes(cid)
    raw = ReportHelper.create_interact_report(cid)
    ret = "Name,Group Name,Metric Name,Score\n"
    raw.each do |e|
      ret += "#{e['name']},#{e['group_name']},#{e['metric_name']},#{e['score']}\n"
    end
    return ret
  end

  # Function to create excel file from arrays
  # +sheets+:: array of sheets to write to excel file. Each sheet is an array by himself, and will
  # be written as rows to the excel sheet. 'sheets' param can contain any number of sheets.
  def create_excel_file(sheets, file_name)
    workbook = create_file_2(file_name)
    sheets.each do |s|
      worksheet  = workbook.add_worksheet
      s.each_with_index do |row_data, i|
        row_data.each_with_index do |column_data, j|
          worksheet.write(i,j, column_data)
        end
      end
    end
    workbook.close
  end
end
