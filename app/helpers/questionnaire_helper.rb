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

  EVENT_TYPE ||= 'QUESTIONNAIRE'

  ##############################################################################
  # Returns a questionnaire's state
  ##############################################################################
  def get_questionnaire_details(token)
    qp = QuestionnaireParticipant.find_by(token: token)
    raise "Not found participant with token: #{token}" if qp.nil?
    raise "Inactive participant" if !qp.active

    aq = Questionnaire.find(qp.questionnaire_id)
    raise "No questionnaire found for participant #{qp.id}" if aq.nil?

    status = nil
    qq     = nil

    ## If its the last question
    if qp.current_questiannair_question_id == -1
      status = 'done'
      qp_status = :completed
      current_questiannair_question_id = nil

    ## Not the last question
    else
      qq = QuestionnaireQuestion.find_by(id: qp.current_questiannair_question_id)

      ## It is nil if it's the first question
      if qq.nil?
        qq = QuestionnaireQuestion
               .where(questionnaire_id: aq.id, active: true)
               .order(:order)
               .first
        raise "No questions defined for questionnaire" if qq.nil?

        status = 'first time'
        qp_status = :entered

      ## Not the first or last question
      else
        status = 'in process'
        qp_status = :in_process
      end
      current_questiannair_question_id = qq.id
    end
      qp.update!(current_questiannair_question_id: current_questiannair_question_id,
                 status: qp_status)

    total_questions = QuestionnaireQuestion
                        .where(questionnaire_id: aq.id, active: true).count

    return {
      q_state: aq.state,
      qp_state: qp.status,
      status: status,
      questionnaire_id: aq.id,
      qpid: qp.id,
      question_id: (qq.nil? ? nil : qq.id),
      depends_on_question: (qq.nil? ? nil : qq.depends_on_question),
      is_funnel_question: (qq.nil? ? nil : qq.is_funnel_question),
      max: (qq.nil? ? nil : qq.max),
      min: (qq.nil? ? nil : qq.min),
      questionnaire_name: aq.name,
      use_employee_connections: aq.use_employee_connections,
      question: (qq.nil? ? nil : qq.body),
      question_title: (qq.nil? ? nil : qq.title),
      current_question_position: (qq.nil? ? nil : qq.question_position),
      total_questions: total_questions
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
  def get_question_participants(token, qd=nil, is_desktop=false)
    qd = get_questionnaire_details(token) if qd.nil?
    qid  = qd[:questionnaire_id]
    qqid = qd[:question_id]
    qpid = qd[:qpid]
    eid = QuestionnaireParticipant.find_by(id: qpid).try(:employee_id)
    raise "Did not find employee for participant: #{qpid}" if eid.nil?
    funnel_question_id = qd[:depends_on_question]
    base_list = []
    client_min_replies = nil

    if qd[:is_funnel_question]
      if qd[:use_employee_connections]
        base_list = get_qps_from_employees_connections(eid)
      else
        base_list = get_qps_from_questionnaire_participants(qid, qpid)
      end

      client_min_replies = qd[:min]
      client_max_replies = qd[:max]
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
      client_min_replies = is_desktop ? 0    : base_list.length
      client_max_replies = base_list.length
    end

    answered_list = QuestionReply
                      .where(questionnaire_id: qid,
                             questionnaire_question_id: qqid,
                             questionnaire_participant_id: qpid)
                      .select(:reffered_questionnaire_participant_id, :answer)

    ret = merge_qps_lists(base_list, answered_list)
    return {
      replies: ret,
      client_min_replies: client_min_replies,
      client_max_replies: client_max_replies
    }
  end


  ##############################################################################
  # This API will attempt to colse current question. If it succeeds it will
  #   update the participant's current_questiannair_question_id field.
  #
  # Returns nil if success, or message with fail reason.
  #
  # If current question is a funnel question then the number of 'true' replies
  #   has to be between min and max values.
  #
  # If current question is dependent question then it has to have replies for
  #   all participants with 'true' replies for the funnel question.
  #
  # If current question is independent question then there are two cases:
  #   1. If not using employees_connections then it has to have replies for
  #      all participants in the quesitonnaire.
  #   2. If using employees_connections then it has to have replies for all
  #      connected employees.
  #
  ##############################################################################
  def close_questionnaire_question(qd)
    qid  = qd[:questionnaire_id]
    qqid = qd[:question_id]
    qpid = qd[:qpid]
    max = qd[:max]
    min = qd[:min]
    qp = QuestionnaireParticipant.find_by(id: qpid)
    eid = qp.try(:employee_id)
    raise "Did not find employee for participant: #{qpid}" if eid.nil?

    fail_res = nil

    answered_list = QuestionReply
                      .where(questionnaire_id: qid,
                             questionnaire_question_id: qqid,
                             questionnaire_participant_id: qpid)
                      .select(:answer)

    if qd[:is_funnel_question]
      selected_qps = answered_list.where(answer: true).pluck(:answer).length
      fail_res = 'Too few participants selected' if selected_qps < min
      fail_res = 'Too many participants selected' if selected_qps > max
    end

    ## Update question
    if fail_res.nil?
      qq = QuestionnaireQuestion.find(qqid)
      next_qq = QuestionnaireQuestion
                  .where(questionnaire_id: qid, active: true)
                  .where("questionnaire_questions.order > #{qq.order}")
                  .order(:order)
                  .first

      next_qq_id = (next_qq.nil? ? -1 : next_qq.id)
      qp.current_questiannair_question_id = next_qq_id
      qp.save!
    end

    return fail_res
  end

  #############################################################################
  # This is the structure that's conssumed by th client, so do not change.
  #############################################################################
  def hash_employees_of_company_by_token(token)
    qp_ids = QuestionnaireParticipant
               .find_by(token: token)
               .questionnaire
               .questionnaire_participant
               .pluck(:id)
    return if qp_ids.nil? || qp_ids.empty?
    query = "select emp.id as id,
            (#{CdsUtilHelper.sql_concat('emp.first_name', 'emp.last_name')}) as name,
            emp.img_url as image_url,
            #{role_origin_field} as role,
            qp.id as qp_id
            from employees as emp
            left join questionnaire_participants as qp on qp.employee_id = emp.id
            left join roles on emp.role_id = roles.id
            left join job_titles on emp.job_title_id = job_titles.id
            where qp.id in (#{qp_ids.join(',')})"
    res = ActiveRecord::Base.connection.select_all(query)
    res = res.to_json
    return res
  end

  #############################################################################
  # Update the participant's replies
  #############################################################################
  def update_replies(qpid, json)
    qp = QuestionnaireParticipant.find_by(id: qpid)
    raise 'No such participant' if qp.nil?
    if !json['replies'].nil?
      QuestionnaireHelper.create_employees_connections(json, qp)
      qp.update_replies(json['replies'])
    end
  end

  def self.freeze_questionnaire_replies_in_snapshot(quest_id, date = Time.now.strftime('%Y-%m-%d'))

    questionnaire = Questionnaire.find_by(id: quest_id)
    raise "Did not find questionnaire for id: #{quest_id}" unless questionnaire
    cid = questionnaire.company.id

    replies = QuestionReply.where(questionnaire_id: quest_id)
    begin
      sid = questionnaire.snapshot_id
      puts "current sid: #{sid}"

      EventLog.log_event(event_type_name: EVENT_TYPE, message: "with name: #{questionnaire.name} copied to snapshot: #{sid}")

      ii = 0
      replies.select { |reply| !reply.answer.nil? }.each do |reply|
        puts "Batch #{ii}" if ((ii % 200) == 0)
        ii += 1
        qqid = reply.questionnaire_question_id
        qq = QuestionnaireQuestion.find_by_id(qqid)
        nid = qq.network_id
        next if nid.nil?
        value = convert_answer(reply.answer)
        from = QuestionnaireParticipant.where(id: reply.questionnaire_participant_id).first
        to = QuestionnaireParticipant.where(id: reply.reffered_questionnaire_participant_id).first

        next unless from && to && from.participant_type != 'tester'

        newfromid = Employee.id_in_snapshot(from.employee.id, sid)
        newtoid   = Employee.id_in_snapshot(  to.employee.id, sid)

        next if (newfromid == nil || newtoid == nil)

        NetworkSnapshotData.find_or_create_by(
          snapshot_id:               sid,
          original_snapshot_id:      sid,
          network_id:                nid,
          company_id:                cid,
          from_employee_id:          newfromid,
          to_employee_id:            newtoid,
          value:                     value,
          questionnaire_question_id: reply.questionnaire_question_id
        )
      end
      questionnaire.update(last_snapshot_id: sid)
      Snapshot.find(sid).update(status: 2)
      sid
    rescue => e
      puts "EXCEPTION: Failed to freeze questionnaire with id: #{quest_id}, error: #{e.message[0..1000]}"
      puts e.backtrace
      raise ActiveRecord::Rollback
    end
  end

  def self.convert_answer(answer)
    return 1 if answer == true
    return 0
  end
  private

  #############################################################################
  # The string that is displayed under the employee's name in the questionnaire
  #############################################################################
  def role_origin_field
    field_name =  CompanyConfigurationTable.display_field_in_questionnaire
    field_name = 'roles.name' if field_name == 'role'
    field_name = 'job_titles.name' if field_name == 'job_title'
    return field_name
  end

  def get_qps_from_employees_connections(eid)
    ret = EmployeesConnection
            .from('employees_connections AS ecs')
            .joins('JOIN questionnaire_participants AS qps ON qps.employee_id = ecs.connection_id')
            .where("ecs.employee_id = ?", eid)
            .select('qps.id, qps.employee_id')
            .pluck('qps.id, qps.employee_id')
    return ret
  end

  def get_qps_from_questionnaire_participants(qid, qpid)
    return QuestionnaireParticipant
             .where(questionnaire_id: qid, active: true)
             .where.not(id: qpid)
             .where.not(participant_type: :tester)
             .select(:id, :employee_id)
             .pluck(:id, :employee_id)
  end

  def get_qps_from_question_replies(qid, funnel_question_id, qpid)
    return QuestionReply
             .from('question_replies AS qr')
             .joins('JOIN questionnaire_participants as qps ON qps.id = qr.reffered_questionnaire_participant_id')
             .where('qr.questionnaire_id = ? ', qid)
             .where('qr.questionnaire_question_id = ?', funnel_question_id)
             .where('qr.questionnaire_participant_id = ?' ,qpid)
             .where('qr.answer = true')
             .select('qps.id, qps.employee_id')
             .pluck('qps.id, qps.employee_id')
  end

  ##############################################################################
  # This is a utility function. It takes a base list of participants relevant
  # to the current question and a list of replies to the same question, and then
  # merges the two into a unified list.
  # The list strucutres are different:
  # - base_list - Is an array of arrays that looks like this:
  #        [[qpid1, eid1], [apid2, eid2], ... ]
  # - answered_list - has this format:
  #        [ {reffered_questionnaire_participant_id: num, answer: <0 | 1>} ... ]
  #
  # It returns:
  #        [ {qpid: number, answer: <true | false | nil>}, ... ]
  ##############################################################################
  def merge_qps_lists(base_list, answered_list)
    hash = {}
    base_list.each do |qp|
      hash[qp[0]] = {e_id: qp[0], employee_details_id: qp[1], answer: nil}
    end

    answered_list.each do |reply|
      elem = hash[reply[:reffered_questionnaire_participant_id]]
      elem[:answer] = reply[:answer]
    end

    return hash.values
  end

  ## Add entries to the employees_connections table base on the replies
  def self.create_employees_connections(json, qp)
    response_emps_ids = json['replies'].map do |r|
      if r['eid'] || r['answer'] == false
        nil
      else
        r['employee_details_id']
      end
    end.compact
    return if response_emps_ids.nil? || response_emps_ids.empty?

    select_query = "select employee_id, connection_id from employees_connections
                    where (employee_id in (#{response_emps_ids.join(',')}) and connection_id = #{qp[:employee_id]})
                    or (employee_id = #{qp[:employee_id]} and connection_id in (#{response_emps_ids.join(',')}))"

    existing_connections = JSON.parse(ActiveRecord::Base.connection.select_all(select_query).to_json)

    values = []
    (response_emps_ids - existing_connections.map { |ec| ec['connection_id'].to_i }).each do |connection_id|
      values << "(#{qp.employee_id}, #{connection_id})"
    end
    (response_emps_ids - existing_connections.map { |ec| ec['employee_id'].to_i }).each do |employee_id|
      values << "(#{employee_id}, #{qp.employee_id})"
    end

    return if values.empty?
    insert_query = "insert into employees_connections (employee_id, connection_id) values #{values.join(',')}"
    ActiveRecord::Base.connection.execute(insert_query)
  end
end
