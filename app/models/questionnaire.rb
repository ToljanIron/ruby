# frozen_string_literal: true
include Mobile::QuestionnaireHelper

class Questionnaire < ActiveRecord::Base
  belongs_to :company
  has_many :questions, through: :questionnaire_questions
  has_many :questionnaire_questions
  has_many :questionnaire_participant
  has_many :employees, through: :questionnaire_participant

  enum state: [:notstarted, :sent, :processing, :completed]

  belongs_to :language

  @@in_process = []
  @@completed = []

  def locale
    return :iw if language && language[:name] == 'Hebrew'
    return :en
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
  # 2 lines in the loop
  def send_questionnaire_email(q_participants)

    EmailMessage.where(questionnaire_participant_id: q_participants).update_all(pending: true)
    pending_emails = EmailMessage.where(pending: true)

    ActionMailer::Base.smtp_settings
    pending_emails.each do |email|
      # Remove comment from next 2 lines when you want to send emails.
      # ExampleMailer.sample_email(email).deliver_now
      # email.send_email
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

    update(state: 2)
    sid = Mobile::QuestionnaireHelper.freeze_questionnaire_replies_in_snapshot(id)

    puts "Working on Snapshot: #{sid}"
    cid = Snapshot.find(sid).company_id
    puts 'In precalculate'
    EventLog.create!(message: "Precalculate for compay: #{cid}, snapshot: #{sid}", event_type_id: 1)
    PrecalculateMetricScoresForCustomDataSystemHelper.cds_calculate_scores_for_generic_networks(cid, sid)

    puts 'Done with precalculate, clearing cache'
    EventLog.create!(message: 'Clear cache', event_type_id: 1)
    Rails.cache.clear
    update(state: 3)
    puts 'Done'
    EventLog.create!(message: 'Freeze questionnaire completed', event_type_id: 1)
  end
end
