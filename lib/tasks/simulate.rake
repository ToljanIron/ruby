DO_NOT_CREATE_ANSWERS = true
AUTO_CREATE_QUESTIONNAIRE = false

def create_company
  @comp = Company.create(name: 'SwiftBurger')
end

def create_employees
  emps = [
    { first_name: 'Sharon',     last_name: '',            email: 'dummy_2', role_type: 'Owner', company_id: @comp.id, active: true },
    { first_name: 'Luke V',     last_name: 'Thomas',      email: 'dummy_0',           role_type: 'President', company_id: @comp.id, active: true },
    { first_name: 'Justin',     last_name: 'Stickles',    email: 'dummy_2',  role_type: 'VP', company_id: @comp.id, active: true },
    { first_name: 'Lee',        last_name: 'Miller',      email: 'dummy_2',  role_type: 'CEO', company_id: @comp.id, active: true },
    { first_name: 'Linda',      last_name: 'Forrest',     email: 'dummy_1',           role_type: 'CFO', company_id: @comp.id, active: true },
    { first_name: 'Nicholas',   last_name: 'Harvey',      email: 'dummy_2',           role_type: 'Accountant', company_id: @comp.id, active: true },
    { first_name: 'Anglea',     last_name: 'Castellanos', email: 'dummy_4',           role_type: 'Logistics Manager', company_id: @comp.id, active: true },
    { first_name: 'Maurice ',   last_name: 'Smith',       email: 'dummy_5',           role_type: 'Purchase Manager', company_id: @comp.id, active: true },
    { first_name: 'Laura ',     last_name: 'Marsh',       email: 'dummy_6',           role_type: 'Branch Manager', company_id: @comp.id, active: true },
    { first_name: 'Hazel ',     last_name: 'Cormier',     email: 'dummy_7',           role_type: 'Branch Manager', company_id: @comp.id, active: true },
    { first_name: 'Leon ',      last_name: 'Ellison',     email: 'dummy_8',           role_type: 'Branch Manager', company_id: @comp.id, active: true },
    { first_name: 'Aleta ',     last_name: 'Cameron',     email: 'dummy_9',           role_type: 'Chipser', company_id: @comp.id, active: true },
    { first_name: 'Jim ',       last_name: 'Wray',        email: 'dummy_10',          role_type: 'Chipser', company_id: @comp.id, active: true },
    { first_name: 'Celia ',     last_name: 'Andrews',     email: 'dummy_11',          role_type: 'Chipser', company_id: @comp.id, active: true },
    { first_name: 'Glen ',      last_name: 'Horn',        email: 'dummy_12',          role_type: 'Chipser', company_id: @comp.id, active: true },
    { first_name: 'Nellie ',    last_name: 'Jones',       email: 'dummy_13',          role_type: 'Chipser', company_id: @comp.id, active: true },
    { first_name: 'Corey ',     last_name: 'Forsman',     email: 'dummy_14',          role_type: 'Chipser', company_id: @comp.id, active: true },
    { first_name: 'Kevin ',     last_name: 'Trask',       email: 'dummy_15',          role_type: 'Chipser', company_id: @comp.id, active: true },
    { first_name: 'Gwen ',      last_name: 'Coggins',     email: 'dummy_16',          role_type: 'Chipser', company_id: @comp.id, active: true },
    { first_name: 'Lisa ',      last_name: 'Tacker',      email: 'dummy_17',          role_type: 'Busboy', company_id: @comp.id, active: true },
    { first_name: 'Dawn ',      last_name: 'Pickett',     email: 'dummy_18',          role_type: 'Busboy', company_id: @comp.id, active: true },
    { first_name: 'Christie ',  last_name: 'Martinez',    email: 'dummy_19',          role_type: 'Busboy', company_id: @comp.id, active: true },
    { first_name: 'Brandi ',    last_name: 'Green',       email: 'dummy_20',          role_type: 'Busboy', company_id: @comp.id, active: true },
    { first_name: 'Michele ',   last_name: 'Russell',     email: 'dummy_21',          role_type: 'Cook', company_id: @comp.id, active: true },
    { first_name: 'Thomas ',    last_name: 'Jones',       email: 'dummy_22',          role_type: 'Cook', company_id: @comp.id, active: true },
    { first_name: 'Michael ',   last_name: 'Michael ',    email: 'dummy_23',          role_type: 'Cook', company_id: @comp.id, active: true },
    { first_name: 'Cheryl ',    last_name: 'Washington',  email: 'dummy_24',          role_type: 'Cook', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
    { first_name: 'Alejandro',  last_name: 'Jones',       email: 'dummy_25',          role_type: 'HR Manager', company_id: @comp.id, active: true },
  ]
  emps.each do |e|
    e[:img_token] = "mobile-#{e[:email]}"
    Employee.create(e)
  end
end

def create_questionnaire
  q = Questionnaire.create(company_id: @comp.id, sent: true)
  q.employees = Employee.all
  q.questions = Question.all
  q.save!
  ap q
  return q
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
      body: 'Indicate the people whom you <b>trust.</b><br><br>
             Please review the list of people and select the most <b>trusted</b> amongst them.',
      order: 3, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true },

    { title: '<b>Advisers</b>',
      body:  'Indicate the people whom you turn to for work related <b>advice,</b> <br>
              people who provide you with answers for work related questions or problems.<br><br>
              Please review the list of people and select whom you take <b>advice</b> form.',
      order: 4, company_id: @comp.id, depends_on_question: 1, min:5 , max: 9, active: true }
  ]

  questions.each do |que|
    Question.create(que)
  end
end

def create_replays
  ids = Employee.all.pluck(:id)
  q = Question.find(1)
  ids.each do |id_1|
    ids.each do |id_2|
      next if id_2 == id_1
      if DO_NOT_CREATE_ANSWERS
        QuestionReply.create(question_id: q.id, employee_id: id_1, reffered_employee_id: id_2, answer: nil)
      else
        r = rand(2)
        case r
        when 1
          answer = true
        else
          answer = false
        end
        case id_1
        when 1
          QuestionReply.create(question_id: q.id, employee_id: id_1, reffered_employee_id: id_2, answer: nil)
        when 2
          QuestionReply.create(question_id: q.id, employee_id: id_1, reffered_employee_id: id_2, answer: answer || nil)
        else
          QuestionReply.create(question_id: q.id, employee_id: id_1, reffered_employee_id: id_2, answer: answer)
        end
      end
    end
  end
  arr = 2
  ap QuestionReply.where(employee_id: arr, answer: nil).count
end

namespace :db do
  desc 'simulate'
  task :simulate, [:with_external_employees] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.transaction do
      begin
        create_company
        create_employees
        create_questions
        # create_replays
      rescue => e
        puts 'got exception:', e.message, e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
