module CsvLoader
  require 'csv'

  module_function

  def create_company(company_name)
    @comp = Company.create(name: company_name)
    @comp.id
  end

  def create_questions(company)
    @comp = company
    questions = [
      { title: '<b>Select 8-15 People</b>',
        body: 'Think about the people who are most important for the way you conduct your work
             These are people who contribute significantly to your work experience. They might be friends, mentors, people you ask for advice or people you report to.
             Please select between 8 to 15 people from the list.',
        order: 1, company_id: @comp.id, min: 8, max: 15, active: true },
      { title: '<b>Friendship</b>',    body: 'Who you consider a (close?) friend.',    order: 2, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Trust</b>',         body: 'Who do you trust.',                      order: 3, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Advice</b>',        body: 'Who do you consult with on professional issues.', order: 4, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Influence</b>',     body: 'Who influences the group.',              order: 5, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Report</b>',        body: 'Who reports to you.',                    order: 6, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Reporting</b>',     body: 'Who do you report to.',                  order: 7, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Fill-in (replace)</b>', body: 'Who can fill-in for you while you’re away.',  order: 8, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Fill for</b>',      body: 'Who can you fill-in for while they’re away.',     order: 9, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Performance</b>',   body: 'Who is important for your good performance.',     order: 10, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Personal</b>',      body: 'Who is important for your personal growth.',      order: 11, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Complementary</b>', body: 'Who would you like to connect with to improve your performance.', order: 12, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Strategic</b>',     body: 'Who is important for your future success.',                       order: 13, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Emotional</b>',     body: 'Who will provide you with emotional support in difficulties times.', order: 14, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Instrumental</b>',  body: 'Who will provide you with tangible aid and assistance when you need them.',           order: 15, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Information</b>',   body: 'Who will provide you with advice, suggestions and information when you need them.',   order: 16, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Appraisal</b>',     body: 'Who can provide you with constructive feedback, affirmation and social comparison.',  order: 17, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Busy</b>',          body: 'Who in the project would increase the projects’ chances to succeed if they had more time.',  order: 18, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Specification</b>', body: 'Who in the project knows best what needs to be done.',     order: 19, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Design</b>',        body: 'Who, in the project, knows best how to do stuff.',         order: 20, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Service</b>',       body: 'Who, in the project, knows best what the customer wants.', order: 21, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },
      { title: '<b>Meta-cognition</b>',body: 'Who, in the project, knows best who in the team knows what.',  order: 22, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true }
    ]

    ap 'create_questions'
    questions.each do |que|
      Question.create(que)
    end
    ap Question.all
  end
end
