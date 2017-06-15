module QuestionnaireRawDataHelper
  require 'csv'

  def self.read_csv_to_db(csv_file)
    values = []
    data = CSV.parse(File.read(csv_file))
    data.shift
    data.each do |row|
      row[5] = '\'' + row[5] + '\''
      values << "(#{row.join(', ')})"
    end
    columns = "(snapshot_id,network_id,company_id,from_employee_external_id,to_employee_external_id,date,value)"
    sql = "INSERT INTO questionnaire_raw_data #{columns} VALUES #{values.join(', ')}"
    begin
      QuestionnaireRawData.connection.execute(sql)
    rescue => e
      raise "Failed to process data. details:\n\t" + e.to_s
    end
  end
end
