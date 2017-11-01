require 'twilio-ruby'

Dotenv.load if Rails.env.development? || Rails.env.onpremise?
FROM        = ENV['TWILIO_FROM_PHONE']
account_sid = ENV['TWILIO_ACCOUNT_SID']
auth_token  = ENV['TWILIO_AUTH_TOKEN']

puts "FROM: #{FROM}"

SMS_PREFIX = ',workships questionnaire is avalible at '
VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

namespace :db do
  desc 'send_pending_questionnaires'
  task :send_pending_questionnaires, [:qid] => :environment do |t, args|
    puts 'send_pending_questionnaires'
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    questionnaire = nil
    ActiveRecord::Base.transaction do
      begin
        questionnaire = Questionnaire.find(args[:qid]) if args[:qid]
        if questionnaire.nil?
          questionnaire = Questionnaire.all
        else
          questionnaire = [questionnaire]
        end
        questionnaire.each do |q|
          q.prepare_for_send
        end
      rescue => e
        puts 'got exception while preparing to send:', e.message, e.backtrace
        EventLog.log_event({event_type_name: 'QUESTIONNAIRE', message: "ERROR sending questionnairei in prepare to send. Error message: #{e.message[0..1000]}"})
        raise ActiveRecord::Rollback
        exit
      end
    end

    ActiveRecord::Base.transaction do
      begin

        client = Twilio::REST::Client.new account_sid, auth_token
        pending_sms = SmsMessage.where(pending: true)
        puts 'sending sms'
        pending_sms.each do |sms|
          puts "working on: #{sms.id}"
          qp = sms.questionnaire_participant
          next unless qp
          emp = qp.employee
          next unless emp
          phone_number = emp.phone_number
          next unless phone_number
          phone_number = phone_number.gsub('-','')
          next unless phone_number.match(/^\d{10}$/)


          sms.update(pending: false)
          client.account.messages.create(
              from: FROM,
              to:  '+972' + phone_number,
              body: ['hello', emp.first_name, SMS_PREFIX, sms.message].join(' ')
            )
          sms.send_sms
          ap "   sent sms with message: #{sms.message}"
        end

        if false
          puts 'sending emails'
          count = 0
          pending_emails = EmailMessage.where(pending: true)
          questionnaire_participant_ids_for_sent = pending_emails.pluck(:questionnaire_participant_id).uniq
          ActionMailer::Base.smtp_settings
          pending_emails.each do |email|
            employee = QuestionnaireParticipant.find(email.questionnaire_participant_id).employee
            # ExampleMailer.sample_email(email).deliver if VALID_EMAIL_REGEX.match employee.email
            email.send_email
            count += 1
            ap "[#{count}] sent email to #{email.questionnaire_participant.employee.email}: #{email.message}"
          end
        end

        questionnaire_sent_id = QuestionnaireParticipant.where(id: questionnaire_participant_ids_for_sent).pluck(:questionnaire_id).uniq
        Questionnaire.where(id: questionnaire_sent_id).each do |q|
          q.state = :sent
          q.sent_date = DateTime.now.strftime("%Y-%m-%d")
          q.save!
          EventLog.log_event({event_type_name: 'QUESTIONNAIRE', message: "with name: #{q.name} sent to employees"})
        end

      rescue => e
        puts 'got exception:', e.message, e.backtrace
        EventLog.log_event({event_type_name: 'QUESTIONNAIRE', message: "ERROR sending questionnaire. Error message: #{e.message[0..1000]}"})
        raise ActiveRecord::Rollback
      end
    end
  end
end
