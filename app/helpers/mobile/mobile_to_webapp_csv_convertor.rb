require 'csv'
module Mobile::CsvTransformer
  def self.start(src_path, cid)
    src = CSV.open(src_path)
    questions_indexes = get_questions_lines(src)
    emps = Company.find(cid).active_employees.order(:id)
    questions_indexes.each do |index|
      question_type = get_question_type(src, index)
      snapshot_date = get_snapshot_date(src, index)
      write_question_to_csv(src, question_type, snapshot_date, emps)
    end
  end

  def self.get_questions_lines(src)
    line_numbers_of_questions = []
    line = 0
    src.each do |row|
      line += 1
      line_numbers_of_questions.push(line) if !row[0].nil? && row[0].include?('<b>')
      end
    end
  def self.get_question_type(src, index)
    return src[index][1].downcase
  end

  def self.get_snapshot_date(src, index)
    return src[index][2].downcase
  end
  def self.write_question_to_csv(src, question_type, snapshot_date, emps)
    csv_file = CSV.open(question_type + '.csv', 'a+')
  end
end
    # advice_csv = CSV.open('advice.csv', 'w')
    # first_line << (emps).each { |i| "#{i.email}" }
    #   friends_names = Employee.find(e.friends).map { |x| x.email }.sort
    #   trusted_names = Employee.find(e.trusted).map { |x| x.email }.sort
    #   advisors_names = Employee.find(e.advisors).map { |x| x.email }.sort
    #   friends_names.unshift(e.email)
    #   trusted_names.unshift(e.email)
    #   advisors_names.unshift(e.email)
    #   friends_csv << friends_names
    #   trust_csv << trusted_namCsvTransformer.start('/home/spectory/Documents/StepAHead files/digital-israel.csv',1)es
    #   advice_csv << advisors_names

    # CsvTransformer.start('/home/spectory/Documents/StepAHead files/digital-israel.csv', 1)