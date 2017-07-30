# frozen_string_literal: true
class SmsController < ApplicationController
  #skip_before_action :verify_authenticity_token

  def receive_and_respond
    authorize :application, :passthrough
    id_number = params['Body'].try(:gsub, ' ', '')
    employee = SmsHelper.find_employee_by_id_number(id_number)
    ret = nil
    event_log_message = nil
    if employee
      ret = SmsHelper.on_success(employee).to_xml
      event_log_message = "Finished handling SMS webhook for id_number: #{id_number}"
    else
      ret = SmsHelper.on_fail.to_xml
      event_log_message = "Failed handling SMS webhook for id_number: #{id_number}"
    end

    EventLog.create!(
      message: event_log_message,
      job_id: -1,
      event_type_id: 1
    )

    render xml: ret
  end
end
