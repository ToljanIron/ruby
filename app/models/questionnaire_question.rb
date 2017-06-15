class QuestionnaireQuestion < ActiveRecord::Base
  belongs_to :question
  has_many :question_replies
  belongs_to :questionnaire

  def init_replies(questionnaire_participants)
    ActiveRecord::Base.transaction do
      questionnaire_participants.each do |e_1|
        questionnaire_participants.each do |e_2|
          next if e_1 == e_2
          q = QuestionReply.find_or_create_by(questionnaire_id: self.questionnaire.id, questionnaire_question_id: id, questionnaire_participant_id: e_1[:id], reffered_questionnaire_participant_id: e_2[:id])
          q.answer = nil
        end
      end
    end
  end

  def dependent_questions
    return Question.where(depends_on_question: order)
  end

  def to_csv
    table = create_answer_table
    res = create_cvs(table)
    return res
  end

  def questionnaire_participants
    return Questionnaire.find(questionnaire_id).questionnaire_participant
  end

  def questionnaire_participants_by_name
    sqlcmd =
      "select qp.*  from questionnaire_participants as qp
       join employees as emp on emp.id = qp.employee_id
       where qp.questionnaire_id = #{questionnaire_id}
       order by emp.last_name, emp.first_name desc"
    res = ActiveRecord::Base.connection.select_all(sqlcmd)
    return res
  end

  private

  def add_table_index_to_employees_and_hash_names(employees)
    names = {}
    employees.each_with_index do |e, i|
      e.update(table_index: i) unless e.table_index
      names[i] = "#{e.email}"
    end
    return names
  end

  def push_first_row_as_question_title(table)
    table.push [title]
  end

  def push_employees_names_as_columns(table, employees, names)
    headers_row = []
    employees.each do |e|
      headers_row[e.table_index + 1] = names[e.table_index]
    end
    table.push headers_row
  end

  def push_empty_rows_to_table(table, employees, names)
    size = employees.count + 1
    employees.each do |e|
      row = Array.new(size)
      row[0] = names[e.table_index]
      table.push row
    end
  end

  def fill_table_with_answers(table, employees)
    emps_ids = employees.pluck(:id)
    rows_offset = 2
    col_offset = 1
    memoize_arr = []
    question_replies = QuestionReply.where(question_id: id, employee_id: emps_ids, reffered_employee_id: emps_ids)
    question_replies.each do |qr|
      unless memoize_arr[qr.employee_id]
        memoize_arr[qr.employee_id] = employees.find(qr.employee_id).table_index
      end
      i = memoize_arr[qr.employee_id]
      unless memoize_arr[qr.reffered_employee_id]
        memoize_arr[qr.reffered_employee_id] = employees.find(qr.reffered_employee_id).table_index
      end
      j = memoize_arr[qr.reffered_employee_id]
      table[i + rows_offset][j + col_offset] = qr.answer
    end
  end

  def create_answer_table
    table = []
    employees = company.active_employees.order(:id)
    names = add_table_index_to_employees_and_hash_names employees
    push_first_row_as_question_title table
    push_employees_names_as_columns(table, employees, names)
    push_empty_rows_to_table(table, employees, names)
    fill_table_with_answers(table, employees)
    return table
  end

  def create_cvs(table)
    res = CSV.generate do |csv|
      table.each do |row|
        csv << row
      end
    end
    return res
  end

end
