# frozen_string_literal: true
include Mobile::QuestionnaireHelper
include XlsHelper
require './lib/tasks/modules/precalculate_metric_scores_for_custom_data_system_helper.rb'

class Questionnaire < ActiveRecord::Base
  include PrecalculateMetricScoresForCustomDataSystemHelper

  belongs_to :company
  has_many :questions, through: :questionnaire_questions
  has_many :questionnaire_questions
  has_many :questionnaire_participant
  has_many :employees, through: :questionnaire_participant


  belongs_to :language

  enum state: [
    :created,
    :delivery_method_ready,
    :questions_ready,
    :notstarted,
    :ready,
    :sent,
    :processing,
    :completed
  ]
  enum delivery_method: [:sms, :email]


  @@in_process = []
  @@completed = []

  def locale
    return :iw if language && language[:name] == 'Hebrew'
    return :en
  end

  def send_q(send_only_to_unstarted, sender_type, eid = nil)
    pending_send =  if eid
                      if self[:pending_send] && self[:pending_send].start_with?('single_employee=')
                        parts = self[:pending_send].split('|')
                        parts.first + ",#{eid}"
                      else
                        "single_employee=#{eid}"
                      end
                    elsif send_only_to_unstarted == 'true'
                      'unstarted'
                    else
                      'all'
                    end
    pending_send += "|#{sender_type}"
    update(pending_send: pending_send)
    self.state = :sent
    save!
  end

  # Reset the questionnaire for this employee. Next time he will enter the questionnaire
  # he will be able to start over.
  def reset_questionnaire_for_emp(emp_id)
    EventLog.create!(message: "resetting questionnaire for id: #{id} and emp #{emp_id}", event_type_id: 1)
    qp = QuestionnaireParticipant.where(questionnaire_id: id, employee_id: emp_id).first
    qp.reset_questionnaire
    EventLog.create!(message: "Done resetting questionnaire for id: #{id} and emp id #{emp_id}", event_type_id: 1)
  end

  # Send questionnaire to specific employee. Will send only if he did not complete
  # the questionnaire
  def send_questionnaire_to_emp(emp_id)
    EventLog.create!(message: "Resending questionnaire for id: #{id}, and emp #{emp_id}", event_type_id: 1)
    qps = QuestionnaireParticipant.where(questionnaire_id: id, employee_id: emp_id).where('status < 3').pluck(:id)
    send_questionnaire_email(qps)
    EventLog.create!(message: "Done resending questionnaire for id: #{id} and emp id #{emp_id}", event_type_id: 1)
  end

  # Resend questionnaire to employees who haven't completed it yet. Employees with 
  # finished state of 3 won't receive this email.
  def resend_questionnaire_to_incomplete
    EventLog.create!(message: "Resending questionnaire for id: #{id}", event_type_id: 1)
    qps = QuestionnaireParticipant.where(questionnaire_id: id).where('status < 3').pluck(:id)
    send_questionnaire_email(qps)
    EventLog.create!(message: "Done resending questionnaire for id: #{id}", event_type_id: 1)
  end

  # Send email to questionnaire participants. This is the actual function which sends the 
  # email, using the Rails mailer. In order to send the emails, you need to uncomment 
  # line in loop
  def send_questionnaire_email(q_participants)

    EmailMessage.where(questionnaire_participant_id: q_participants).update_all(pending: true)
    pending_emails = EmailMessage.where(pending: true)
    puts "************************"
    ActionMailer::Base.smtp_settings
    pending_emails.each do |email|

      puts "Sending mail..."
      puts "************************"
      # Remove comment from next line when you want to send emails.
      ExampleMailer.sample_email(email).deliver_now
      email.send_email
      puts "\n\nWARNING: Emails will not be sent. Check MAILER_ENABLED env var\n\n#{(caller.to_s)[0...1000]}\n\n" if !(ENV['MAILER_ENABLED'].to_s.downcase == 'true')
    end
  end

  def last_submitted
    Snapshot.find(last_snapshot_id)[:updated_at]
  rescue
    nil
  end

  def prepare_for_send
    return unless pending_send
    target, method, type = pending_send.split('|')
    if target == 'unstarted'
      check_replies_status
      resent_employees = unstarted_questionnaire_participant
    elsif target.start_with?('single_employee=')
      eids = target.split('=').last.split(',').map(&:to_i)
      resent_employees = questionnaire_participant.where(questionnaire_id: id, employee_id: eids)
    else
      resent_employees = questionnaire_participant.where(active: true)
    end
    # questionnaire_questions.each do |q|
    #   q.init_replies(resent_employees) unless q.active == false
    # end
    add_pending_questionnaire(resent_employees, method, type)
    update(pending_send: nil)
  end

  def unstarted_questionnaire_participant
    return questionnaire_participant.select { |e| e.question_replies.where(answer: [true, false]).count == 0 && e.active == true }
  end

  def employees_in_process
    return @@in_process
  end

  def employees_completed
    return @@completed
  end

  def check_replies_status
    @@in_process = []
    @@completed = []
    true_or_false = [true, false]
    return unless state == 'sent'
    emp_ids = questionnaire_participant.where(active: true).pluck(:id)
    qustions_ids = questionnaire_questions.pluck(:id)
    questionnaire_participant.each do |e|
      emp_ids.delete e.id
      unanswered_exists = find_unanswered_question(qustions_ids, e.id, emp_ids)
      answered_exists = QuestionReply.find_by(questionnaire_question_id: qustions_ids, questionnaire_participant_id: e.id, reffered_questionnaire_participant_id: emp_ids, answer: true_or_false)
      if answered_exists
        if unanswered_exists
          @@in_process.push e
        else
          @@completed.push e
        end
      end
      emp_ids.push e.id
    end
    @@in_process.uniq!
    @@completed.uniq!
  end

  def find_unanswered_question(questionnaire_question_ids, e_id, emp_ids)
    res = nil
    questionnaire_question_ids.select { |q_id| QuestionnaireQuestion.find(q_id).active == true } .each do |q_id|
      questionnaire_question = QuestionnaireQuestion.find(q_id)
      total_answers = QuestionReply.where(questionnaire_question_id: q_id, questionnaire_participant_id: e_id, reffered_questionnaire_participant_id: emp_ids, answer: [true, false])
      if questionnaire_question.min
        res = questionnaire_question if total_answers.where(answer: true).count < questionnaire_question.min
      else
        res = questionnaire_question if total_answers.count < QuestionReply.where(questionnaire_question_id: q_id, questionnaire_participant_id: e_id, reffered_questionnaire_participant_id: emp_ids).count
      end
      return true if res
    end
    return false
  end

  def size
    return questionnaire_questions.where(active: true).count
  end

  def question_position(q_id)
    arr = questionnaire_questions.where(active: true).order(:order).pluck(:id)
    return arr.find_index(q_id) + 1
  end

  def questionnaire_participant_ids
    return QuestionnaireParticipant.where(questionnaire_id: id, active: true).pluck(:id)
  end

  def freeze_questionnaire
    puts 'Freezing'
    puts "Working on questionnaire ID: #{id}"
    EventLog.create!(message: "Freezing questionnaire id: #{id}", event_type_id: 1)

    if state != 'sent'
      msg = "Questionnaire in state: #{state} and is not ready to be processed into a snapshot, aboriting."
      puts msg
      EventLog.create!(message: msg, event_type_id: 1)
      return
    end

    update(state: :processing)
    sid = Mobile::QuestionnaireHelper.freeze_questionnaire_replies_in_snapshot(id)

    puts "Working on Snapshot: #{sid}"
    cid = Snapshot.find(sid).company_id
    puts 'In precalculate'
    EventLog.create!(message: "Precalculate for compay: #{cid}, snapshot: #{sid}", event_type_id: 1)
    cds_calculate_scores_for_generic_networks(cid, sid)
    #PrecalculateMetricScoresForCustomDataSystemHelper.cds_calculate_scores_for_generic_networks(cid, sid)

    puts 'Done with precalculate, clearing cache'
    EventLog.create!(message: 'Clear cache', event_type_id: 1)
    Rails.cache.clear
    update(state: :completed)
    puts 'Done'
    EventLog.create!(message: 'Freeze questionnaire completed', event_type_id: 1)
  end

  def generate_report
    sheets = []
    company_name = Company.where(id: company_id).first.name
    public_folder = 'public'
    report_folder = 'questionnaire_reports'
    report_name = "questionnaire_report_company_#{company_name}.xls"
    report_path = "#{public_folder}/#{report_folder}/#{report_name}"

    Dir.mkdir("#{public_folder}/#{report_folder}") unless Dir.exists?("#{public_folder}/#{report_folder}")

    sheets << ReportHelper.get_questionnaire_report_raw(company_id)

    quest_scores_report_raw = parse_gender(ReportHelper.create_interact_report(company_id))

    sheets << hashes_to_arr(quest_scores_report_raw)

    quest_network_report_raw = parse_gender(ReportHelper.create_snapshot_report(company_id))
    sheets << hashes_to_arr(quest_network_report_raw)

    XlsHelper.create_excel_file(sheets, report_path)
    return "#{report_folder}/#{report_name}"
  end

  # Move to some util helper
  def hashes_to_arr(arr_of_hashes)
    res = []
    return if arr_of_hashes.nil?
    keys = arr_of_hashes[0].keys
    res << keys
    arr_of_hashes.each {|h| res << h.values}

    return res
  end

  def parse_gender(data)
    data.each do |d|
      d.each do |key, val|
        d[key] = val == 0 ? 'male' : 'female' if(key.to_s.downcase.include?('gender'))
      end
    end
    return data
  end

  #####################################################################
  # Get all questionnaires with number of particpants in each statge
  #####################################################################
  def self.get_all_questionnaires(cid)
    qids = Questionnaire.where(company_id: cid).pluck(:id)
    return get_questionnaires(qids)
  end

  def self.get_one_questionnaire(qid)
    return get_questionnaires([qid])
  end

  def self.get_questionnaires(qids)
    sqlstr =
      "SELECT count(*), qp.status, q.id, q.name, q.sent_date, q.delivery_method,
              q.sms_text, q.email_text, q.email_from, q.email_subject, q.test_user_name,
              q.test_user_phone, q.test_user_email, q.state, q.language_id
       FROM questionnaire_participants AS qp
       JOIN questionnaires AS q ON q.id = qp.questionnaire_id
       WHERE q.id in ( #{qids.join(',')})
       GROUP BY qp.status, q.id, q.name, q.sent_date, q.delivery_method,
                q.sms_text, q.email_text, q.email_from, q.email_subject, q.test_user_name,
                q.test_user_phone, q.test_user_email, q.state, language_id
       ORDER BY snapshot_id DESC"

    res = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    ap res
    ret = []
    res.each do |r|
      quest = ret.find {|e| e['id'] == r['id'] }
      if quest.nil?
        quest = r
        quest['stats'] = []
        ret << quest
      end
      quest['stats'][r['status']] = r['count']
    end
    return ret
  end

  def self.state_name_to_number(state)
    ret = nil
    case state
      when 'created'
        ret = 0
      when 'delivery_method_ready'
        ret = 1
      when 'questions_ready'
        ret = 2
      when 'notstarted'
        ret = 3
      when 'ready'
        ret = 4
      when 'sent'
        ret = 5
      when 'processing'
        ret = 6
      when 'completed'
        ret = 7
      else
        raise "Unknown state: #{state}"
    end
    return ret
  end
end
