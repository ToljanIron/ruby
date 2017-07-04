module Mobile::CsvLoader
  require 'csv'

  module_function

  def create_company(company_name)
    ap 'create_company'
    @comp = Company.create(name: company_name)
    @comp.id
  end

  def csv_to_emps(path_to_csv_file, company_name)
    CSV::Converters[:blank_to_nil] = lambda do |field|
      field && field.empty? ? nil : field
    end
    CSV.foreach(path_to_csv_file, headers: true, header_converters: :symbol, converters: [:blank_to_nil]) do |row|
      roletype = row[:role_type]
      if roletype && roletype.length > 16
        fail "role type is bigger than 16 chars for the emp: #{row[:first_name]} #{row[:last_name]}"
      end
      email_regex = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/
      unless email_regex.match(row[:email])
        fail "A wrong email was entered for: #{row[:first_name]} #{row[:last_name]} ==> #{row[:email]}"
      end

      if ENV['ON_PREMISE']
        img_url = '/employees/' +  row[:email] + '.jpg'
        x = Employee.create!(first_name: row[:first_name], img_url: img_url, last_name: row[:last_name], email: row[:email], role_type: row[:role_type], company_id: company_name, active: true)
      else
        x = Employee.create!(first_name: row[:first_name], last_name: row[:last_name], email: row[:email], role_type: row[:role_type], company_id: company_name, active: true)
      end
      x.save!
    end
  end

  def create_questions
    questions = [
      { title: '<b>Select 8-15 People</b>',
        body: 'Think about the people who are most important for the way you conduct your work
             These are people who contribute significantly to your work experience. They might be friends, mentors, people you ask for advice or people you report to.
             Please select between 8 to 15 people from the list.',
        order: 1, company_id: @comp.id, min: 8, max: 15, active: true },
      { title: '<b>Friendship</b>',
        body: 'Indicate the people whom you view as your friends at work.<br>
               Friends are the people whom you enjoy spending time with, and whom you can discuss personal issues with.<br><br>
               Please review the list of people and select the <b>friends</b> amongst them.',
        order: 2, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },

      { title: '<b>Trust</b>',
        body: 'Indicate the people whom you trust.
               Please review the list of people and select the most trusted amongst them.',
        order: 3, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },

      { title: '<b>Advisers</b>',
        body:  'Indicate the people whom you turn to for work related advice,
                people who provide you with answers for work related questions or problems.
                Please review the list of people and select whom you take advice form.',
        order: 4, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true }
    ]

    ap 'create_questions'
    questions.each do |que|
      Question.create(que)
    end
    ap Question.all
  end
end
