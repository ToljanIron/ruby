# frozen_string_literal: true
module SmsHelper
  DEFAULT_SUCCESSMSG = 'Welcome to StepAhead employee evaluation questionnaire. Click on the following link to start the questionnaire:'
  FAILMSG = 'Welcome to StepAhead employee evaluation questionnaire. The ID number you sent is not registered. Send the correct ID again or contact support.'

  def self.on_success(employee)
    participant = employee.questionnaire_participants.order(:questionnaire_id).last
    link = participant.create_link
    questionnaire = participant.questionnaire
    generate_message("#{questionnaire[:sms_text] || DEFAULT_SUCCESSMSG} #{link}")
  end

  def self.on_fail
    generate_message(FAILMSG)
  end

  def self.generate_message(text)
    twiml = Twilio::TwiML::Response.new do |r|
      r.Message text
    end

    twiml
  end

  def self.find_employee_by_id_number(idn)
    employee = Employee.find_by(id_number: idn)
    return employee if employee
    idn_length = idn.length
    return nil if idn_length == 9 && idn[0] != '0'
    new_idn = idn[1..-1]
    return Employee.find_by(id_number: new_idn)
  end
end
