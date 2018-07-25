module Mobile
module QuestionnaireHelper
  require 'csv'

  EVENT_TYPE = 'QUESTIONNAIRE'

  def add_pending_questionnaire(questionnaire_participants, sender_type, type = nil)
    if type.nil?
      questionnaire_participants.each do |participant|
        e = participant.employee
        create_sms participant if sender_type == 'sms' && e.phone_number
        create_email participant if sender_type == 'email' && e.email
      end
    elsif type == 'desktop'
      questionnaire_participants.each do |participant|
        e = participant.employee
        create_desktop_sms participant if sender_type == 'sms' && e.phone_number
        create_desktop_email participant if sender_type == 'email' && e.email
      end
    end
  end

  def self.reset_questionnire_for_employee(emp)
    QuestionReply.where(employee: emp).update_all(answer: nil)
    emp.current_question_id = nil
    emp.save!
  end

  def self.delete_all_replies(qid)
    QuestionReply.where(questionnaire_id: qid).update_all(answer: nil)
    QuestionnaireParticipant.where(questionnaire_id: qid).update_all(current_questiannair_question_id: nil, in_continue_later_status: nil)
    # Employee.save!
  end

  def self.export_csv_files(src_path, cid)
    src = []
    CSV.foreach(src_path, :headers => false) do |row|
      src.push(row)
    end
    create_headers
    questions_indexes = get_questions_lines(src)
    emps = Employee.by_company(cid).order(:id)
    questions_indexes.each do |index|
      question_type = get_question_type(src, index)
      snapshot_date = get_snapshot_date(src, index)
      formatted_question = get_csv_question(src, snapshot_date, emps, index)
      write_question_to_csv(formatted_question, question_type)
    end
  end

  def self.get_questions_lines(src)
    line_numbers_of_questions = []
    line = 0
    src.each do |row|
      line_numbers_of_questions.push(line) if !row[0].nil? && row[0].include?('<b>')
      line += 1
    end
    return line_numbers_of_questions
  end

  def self.get_question_type(src, index)
    return src[index][1].downcase
  end

  def self.get_snapshot_date(src, index)
    return src[index][2].downcase
  end

  def self.get_csv_question(src, snapshot_date, emps, index_start)
    ans = []
    start_of_emp_lines = index_start + 2
    end_of_emp_lines = start_of_emp_lines + emps.count - 1
    (start_of_emp_lines..end_of_emp_lines).each do |row|
      src[row].each_with_index do |col, index|
        if col == 'true'
          ans << [src[row][0], src[index_start + 1][index], 1, snapshot_date]
        end
      end
    end
    return ans
  end

  def self.write_question_to_csv(app_formatted_csv_question, question_type)
    csv_file = CSV.open("#{question_type}" + '.csv', 'a+')
    app_formatted_csv_question.each do |row|
      csv_file << row
    end
    csv_file.close
  end

  def self.create_headers
    csv_target = CSV.open("advice.csv", 'w')
    csv_target << ["employee", "advicee", "advice_flag", "snapshot"]
    csv_target.close
    csv_target = CSV.open("trust.csv", 'w')
    csv_target << ["employee", "trusted", "trust_flag", "snapshot"]
    csv_target.close
    csv_target = CSV.open("friendships.csv", 'w')
    csv_target << ["employee", "friend", "friend_flag", "snapshot"]
    csv_target.close
  end

  def self.create_questionnaire(cid, name, language_id = nil, sms_text = nil)
    quest = Questionnaire.create!(company_id: cid, name: name, language_id: language_id, sms_text: sms_text)
    sid = Snapshot.last_snapshot_of_company(cid)
    emps = Employee.by_snapshot(sid)
    emps.each do |emp|
      next if emp[:email] == 'other@mail.com'
      QuestionnaireParticipant.create!(employee_id: emp.id, questionnaire_id: quest.id)
    end
    questions = Question.all
    questions.each do |q|
      QuestionnaireQuestion.create!(
        company_id:          cid,
        question_id:         q.id,
        questionnaire_id:    quest.id,
        title:               q.title,
        body:                q.body,
        order:               q.order,
        depends_on_question: q.depends_on_question,
        min:                 q.min,
        max:                 q.max,
        active:              false
      )
    end

    EventLog.log_event({event_type_name: EVENT_TYPE, message: "with name: #{quest.name} created"})
    return quest
  end

  def self.list_questionnaire_questions(quest_id)
    ret = []
    questions = QuestionnaireQuestion.where(questionnaire_id: quest_id).order(:id)
    questions.each do |qq|
      question = {
        questionnaire_question_id: qq.id,
        questionnaire_id: qq.questionnaire_id,
        title: qq.title,
        body:  qq.body,
        order: qq.order,
        depends_on_question: qq.depends_on_question,
        min:   qq.min,
        max:   qq.max,
        active: qq.active,
        network_name: NetworkName.where(id: qq.network_id).first.try(:name)
      }
      ret << question
    end
    return ret
  end

  def self.set_active_questions(quest_id, questions_arr)
    questions = QuestionnaireQuestion.where(questionnaire_id: quest_id)
    questions.each do |qq|
      qq.update_attribute(:active, true) if questions_arr.include? qq.id
    end
  end

  def self.list_questionnaire_emps(quest_id)
    ret = []
    qps = QuestionnaireParticipant.where(questionnaire_id: quest_id).order(:id)
    qps.each do |qp|
      emp = qp.employee
      question = {
        questionnaire_participant_id: qp.id,
        email:      emp.email,
        first_name: emp.first_name,
        last_name:  emp.last_name,
        img_url: emp.img_url,
        active: qp.active,
        role_type: emp.role.try(:name)
      }
      ret << question
    end
    return ret
  end

  def self.set_active_employees(quest_id, emps_arr)
    emps = QuestionnaireParticipant.where(questionnaire_id: quest_id)
    emps.each do |emp|
      emp.update_attribute(:active, true)  if emps_arr.include? emp.id
      emp.update_attribute(:active, false) if !emps_arr.include? emp.id
    end
  end

  def self.update_questionnaire(cid, questionnaire_id, name, language_id = nil, sms_text = nil)
    return if  cid.nil? || questionnaire_id.nil?
    questionnaire = Questionnaire.where(id: questionnaire_id, company_id: cid).first
    questionnaire.update(name: name, language_id: language_id, sms_text: sms_text)
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
          next unless from && to

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

  def self.get_questionnaire_details(quest_id)
    @questionnaire = {
      employees: list_questionnaire_emps(quest_id),
      questions: list_questionnaire_questions(quest_id)
    }
    return @questionnaire
  end

  def self.get_questionnair_active_participants(questionnaire)
    return questionnaire.questionnaire_participant.where(active: true).count
  end

  def self.get_questionnair_completed_percentage_participants(questionnaire)
    relevant_participants = questionnaire.questionnaire_participant.where(active: true)
    last_questionnaire_question = questionnaire.questionnaire_questions.where(active: true)
    last_questionnaire_question = last_questionnaire_question.order(order: :desc).first.id unless last_questionnaire_question.nil? || last_questionnaire_question.empty?
    res = 0
    relevant_participants.each do |participant|
      res += 1 if participant.current_questiannair_question_id == last_questionnaire_question
    end
    return '0%' if res == 0
    return ((res.to_f/relevant_participants.count.to_f)*100).round(1).to_s + '%'
  end

  private

  def create_sms(participant)
    sms = SmsMessage.find_or_create_by(questionnaire_participant_id: participant.id)
    sms.update(pending: true, message: participant.create_link)
  end

  def create_email(participant)
    email = EmailMessage.find_or_create_by(questionnaire_participant_id: participant.id)
    email.update(pending: true, message: participant.create_link)
  end

  def create_desktop_sms(participant)
    sms = SmsMessage.find_or_create_by(questionnaire_participant_id: participant.id)
    sms.update(pending: true, message: participant.create_link)
  end

  def create_desktop_email(participant)
    email = EmailMessage.find_or_create_by(questionnaire_participant_id: participant.id)
    email.update(pending: true, message: participant.create_link)
  end

end
end
