# frozen_string_literal: true
class QuestionnaireParticipant < ActiveRecord::Base
  belongs_to :employee
  belongs_to :questionnaire
  has_many :question_replies

  BIG_NUMBER = 1000

  enum status: [:notstarted, :entered, :in_process, :completed]

  def create_link
    create_token
    if Rails.env == 'test' || Rails.env == 'development'
      base_url = 'http://localhost:3000/'
    else
      Dotenv.load
      base_url = ENV['STEPAHEAD_BASE_URL']
    end

    return base_url + "/questionnaire?token=#{token}"
  end

  def create_token
    update(token: SecureRandom.hex) unless token
  end

  def update_replies(replies)
    curr_questionnaire_question = find_questionnaire_question(replies)
    replies.select { |r| !r[:answer].nil? }.each do |r|
      qr = QuestionReply.where(questionnaire_id: questionnaire_id,
                               questionnaire_question_id: curr_questionnaire_question.id,
                               questionnaire_participant_id: id,
                               reffered_questionnaire_participant_id: r[:e_id])

      if qr.empty?
        if r[:e_id].blank?
          qp = QuestionnaireParticipant.find_by(employee_id: r[:employee_details_id], questionnaire_id: questionnaire_id)
          r[:e_id] = qp.id
        end
        QuestionReply.create!(questionnaire_id: questionnaire_id,
                              questionnaire_question_id: curr_questionnaire_question.id,
                              questionnaire_participant_id: id,
                              reffered_questionnaire_participant_id: r[:e_id],
                              answer: r[:answer])
      else
        qr.update_all(answer: r[:answer])
      end
    end
  end

  def find_next_question
    return QuestionnaireQuestion.find(current_questiannair_question_id), 'in process' if in_continue_later_status && current_questiannair_question_id
    res = nil
    answer_count = nil
    q_replies = nil
    q_index = 0
    status = 'in process'
    arr = questionnaire.questionnaire_questions.where(active: true).order(:order)
    arr.each do |qq|
      res = qq
      q_index += 1
      q_replies = question_replies
      answer_count = q_replies.where(answer: [true, false]).count
      break unless question_completed?(qq)
      status = 'done' if q_index == arr.count
    end
    status = 'first time' if answer_count.zero? && q_index == 1
    return res, status
  end

  def question_completed?(qq)
    return dependent_quesiton_completed?(qq) unless qq.depends_on_question.nil?
    return independent_quesiton_completed?(qq)
  end

  def independent_quesiton_completed?(qq)
    min     = qq.min.nil? ? BIG_NUMBER : qq.min
    answers = qq.question_replies.where(questionnaire_participant_id: id).count
    return answers >= min
  end

  def dependent_quesiton_completed?(qq)
    min = filter_only_relevant_qp(qq).count
    answers = qq.question_replies.where(questionnaire_participant_id: id).count
    return answers >= min
  end

  def all_replies_for_questionnaire_question(q_id)
    res = []

    questionnaire_question = QuestionnaireQuestion.find(q_id)
    order_of_dependent_question = QuestionnaireQuestion.find(q_id).depends_on_question
    if order_of_dependent_question.nil?
      emps = if populate_automatically(questionnaire_question)
               QuestionnaireParticipant.find(filter_only_relevant_qp(questionnaire_question))
             else
               questionnaire_question.questionnaire_participants_by_name
             end
      emps.each do |qp|
        next if qp['id'] == id
        obj = {}
        obj[:employee_details_id] = qp['employee_id'].to_i
        obj[:e_id] = qp['id']
        obj[:answer] = nil
        res.push obj
      end
    else
      qps = QuestionnaireParticipant.find(filter_only_relevant_qp(questionnaire_question))
      qps.each do |qp|
        obj = {}
        obj[:employee_details_id] = qp.employee.id
        obj[:e_id] = qp.id
        obj[:answer] = nil
        res.push obj
      end
    end
    return res
  end

  def filter_only_relevant_qp(qq)
    if populate_automatically(qq)
      emps_arr = EmployeesConnection.where(employee_id: employee.id).pluck(:connection_id)
      selected_qps_ids = QuestionnaireParticipant.where(employee_id: emps_arr, questionnaire_id: questionnaire_id).pluck(:id)
    else
      selected_qps_ids = QuestionnaireQuestion
                           .find_by(order: qq.depends_on_question, questionnaire_id: qq.questionnaire_id)
                           .question_replies.where(questionnaire_participant_id: id, answer: true)
                           .pluck(:reffered_questionnaire_participant_id)
    end
    return selected_qps_ids
  end

  ## In order to decide whether to populate from EmployeesConnection or from
  ##   the first question need to find out whether the system was configured to
  ##   load questionnaire participants from the employees_connections table. Then
  ##   need to understand whether there was an independent question already or not,
  ##   because if there was then it has populated resultas.
  def populate_automatically(qq)
    independent_question_was_populated = false
    qid = qq.questionnaire_id

    depends_on_question = qq.depends_on_question
    if !depends_on_question.nil?
      ind_question_id =  QuestionnaireQuestion.find_by(questionnaire_id: qid, order: qq.depends_on_question).try(:id)
      independent_question_was_populated = true if !ind_question_id.nil?
    end

    populate_from_employees_connections = CompanyConfigurationTable.find_by(key: 'populate_questionnaire_automatically', comp_id: employee[:company_id])
    populate_from_employees_connections = populate_from_employees_connections && populate_from_employees_connections[:value] == 'true'

    return populate_from_employees_connections && !independent_question_was_populated
  end

  def self.update_questionnaire_participant_status(status, current_question_position, total_questions = -1)
    return :entered if (status == 'first time' || current_question_position == 1) && total_questions != 1
    return :in_process if status == 'in process'
    return :completed if status == 'done'
  end

  def total_questions_answered
    return 0 if status == 'notstarted' || status == 'entered' || current_questiannair_question_id.nil?
    QuestionnaireQuestion.find(current_questiannair_question_id)[:order] - (status == 'in_process' ? 1 : 0)
  end

  def last_action
    question_replies.try(:pluck, :updated_at).max
  end

  def gt_locale
    return :iw if questionnaire.language.name == 'Hebrew'
    return :en
  end

  def reset_questionnaire
    update(current_questiannair_question_id: nil, status: 0)
    QuestionReply.where(questionnaire_id: questionnaire_id, questionnaire_participant_id: id).delete_all
  end

  private

  def get_relevant_emps(dependent_question)
    return dependent_question.question_replies.where(questionnaire_participant_id: id, answer: true).pluck(:reffered_questionnaire_participant_id)
  end

  def find_questionnaire_question(_replies)
    return QuestionnaireQuestion.find(current_questiannair_question_id)
  end
end
