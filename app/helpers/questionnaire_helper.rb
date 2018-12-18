################################################################################
=begin

This file is where ALL of questionnaire related API processing should be
carried out. The functions here reflect the API structure and are all
tested in the spec.

Questionnaires may have several variants. The following list depicts all of
 them:

1. The first question may be a funnel question. It is used when the quest'
   includes many participants and to enable participants to narrow down the list
   the initially select the subset of participants about whom they will reply.
2. Participants can be drawn from the entire pool or from a pre-selected set.
   This set is represented by the relations in the employee_connections table.
3. Any subsequent question is either dependant on the replies of the initial
   funnel question, or is independent. A funnel question is independant by
   definition.

The min/max numbers on the questions are related only to funnel questions.
  These numbers define the range of participants the current participant should
  select
Non-funnel questions do not have min/max numbers and the current participant
  should anser yes or no on everyone in his list

=end
################################################################################

module QuestionnaireHelper

  ##############################################################################
  # Returns a questionnaire's state
  ##############################################################################
  def get_questionnaire_details(token)
    qp = QuestionnaireParticipant.find_by(token: token)
    raise "Not found participant with token: #{token}" if qp.nil?
    raise "Inactive participant" if !qp.active

    aq = Questionnaire.find(qp.questionnaire_id)
    raise "No questionnaire found for participant #{qp.id}" if aq.nil?

    qq = QuestionnaireQuestion.find_by(id: qp.current_questiannair_question_id)
    if qq.nil?
      qq = QuestionnaireQuestion
             .where(questionnaire_id: aq.id, active: true)
             .order(:order)
             .first
    end
    raise "No questions defined for questionnaire" if qq.nil?

    total_questions = QuestionnaireQuestion
                        .where(questionnaire_id: aq.id, active: true).count

    return {
      q_state: aq.state,
      qp_state: qp.status,
      questionnaire_id: aq.id,
      qpid: qp.id,
      question_id: qq.id,
      depends_on_question: qq.depends_on_question,
      is_funnel_question: qq.is_funnel_question,
      max: qq.max,
      min: qq.min,
      questionnaire_name: aq.name,
      total_questions: total_questions,
      use_employee_connections: aq.use_employee_connections,
      question_body: qq.body,
      question_title: qq.title
    }
  end

  ##############################################################################
  # Returns a list like this:
  #   [ {qpid: number, answer: <true | false | nil>}, ... ]
  #
  # where answer is true    if participant was selected as YES,
  #       answer is false   if participant was seledted as NO,
  #       answer is nil     if participant was not selected yet.
  #
  # The mobile app is expected to display only un-selected participants.
  # The desktop app is expected to display as selected only participants marked
  #   with 1, the rest should appear in the un-selected pool on the right.
  #
  # The list is made up of two parts selected and unselected.
  #   - selected participants are extructed from the question_replies table.
  #   - un-selected participants extruction depends on the use_employee_connections
  #     flag.
  #     If it is false, then these are questionnaire_participants that do not
  #       appear yet in the question_replies.
  #     If it is true, then these are employees_connections that do not
  #       appear yet in the question_replies.
  #
  ##############################################################################
  def get_question_participants(token)
    qd = get_questionnaire_details(token)
    qid  = qd[:questionnaire_id]
    qqid = qd[:question_id]
    qpid = qd[:qpid]
    eid = QuestionnaireParticipant.find_by(id: qpid)
    raise "Did not find employee for participant: #{qpid}" if eid.nil?
    funnel_question_id = qd[:depends_on_question]
    base_list = []

    if qd[:is_funnel_question]
      if qd[:use_employee_connections]
        base_list = get_qps_from_employees_connections(eid)
      else
        base_list = get_qps_from_questionnaire_participants(qid, qpid)
      end
    else
      if !qd[:depends_on_question].nil?
        base_list = get_qps_from_question_replies(qid, funnel_question_id, qpid)
      else
        if qd[:use_employee_connections]
          base_list = get_qps_from_employees_connections(eid)
        else
          base_list = get_qps_from_questionnaire_participants(qid, qpid)
        end
      end
    end

    answered_list = QuestionReply
                      .where(questionnaire_id: qid,
                             questionnaire_question_id: qqid,
                             questionnaire_participant_id: qpid)
                      .select(:reffered_questionnaire_participant_id, :answer)

    ret = merge_qps_lists(base_list, answered_list)
    return ret
  end

  ##############################################################################
  # This is a utility function. It takes a base list of participants relevant
  # to the current question and a list of replies to the same question, and then
  # merges the two into a unified list.
  # The list strucutres are different:
  # - base_list - Is a numbers array of questionnaire_participants
  # - answered_list - has this format:
  #        [ {reffered_questionnaire_participant_id: num, answer: <0 | 1>} ... ]
  #
  # It returns:
  #        [ {qpid: number, answer: <true | false | nil>}, ... ]
  ##############################################################################
  def merge_qps_lists(base_list, answered_list)
    hash = {}
    base_list.each do |qpid|
      hash[qpid] = {qpid: qpid, answer: nil}
    end

    answered_list.each do |reply|
      elem = hash[reply[:reffered_questionnaire_participant_id]]
      elem[:answer] = reply[:answer]
    end

    return hash.values
  end

  private

  def get_qps_from_employees_connections(eid)
    return EmployeesConnection
             .where(employee_id: eid)
             .select(:connection_id)
             .pluck(:connection_id)
  end

  def get_qps_from_questionnaire_participants(qid, qpid)
    return QuestionnaireParticipant
             .where(questionnaire_id: qid, active: true)
             .where.not(id: qpid)
             .where.not(participant_type: :tester)
             .select(:id).pluck(:id)
  end

  def get_qps_from_question_replies(qid, funnel_question_id, qpid)
    return QuestionReply
             .where(questionnaire_id: qid,
                    questionnaire_question_id: funnel_question_id,
                    questionnaire_participant_id: qpid,
                    answer: true)
             .select(:reffered_questionnaire_participant_id)
             .pluck(:reffered_questionnaire_participant_id)
  end
end
