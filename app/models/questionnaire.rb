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

  def send_q_desktop(send_only_to_unstarted, sender_type)
    pending_send = send_only_to_unstarted == 'true' ? 'unstarted' : 'all'
    pending_send += "|#{sender_type}|desktop"
    update(pending_send: pending_send)
    self.state = :sent
    save!
  end

  def resend_questionnaire
    puts "Resceived resend_questionnaire for ID: #{id}"
    EventLog.create!(message: "Resending questionnaire for id: #{id}", event_type_id: 1)
    qps = QuestionnaireParticipant.where(questionnaire_id: id).where('status < 3').pluck(:id)
    EmailMessage.where(questionnaire_participant_id: qps).update_all(pending: true)
    pending_emails = EmailMessage.where(pending: true)

    ActionMailer::Base.smtp_settings
    pending_emails.each do |email|
      
      # ExampleMailer.sample_email(email).deliver_now
      # email.send_email
      puts "\n\nWARNING: EMail will not be sent. Check MAILER_ENABLED env var\n#{(caller.to_s)[0...1000]}\n\n" if !(ENV['MAILER_ENABLED'].to_s.downcase == 'true')
    end
    EventLog.create!(message: "Done resending questionnaire for id: #{id}", event_type_id: 1)
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
