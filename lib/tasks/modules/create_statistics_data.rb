
module CreateStatisticsData

  def calculate_all_statistics(cid, sid)
    number_of_employees = getNumberOfEmployees
    amount_of_email_analyzed = getAmountOfEmailAnalayzed(sid)
    least_amount_of_emails_sent_to_an_employee = getAmountOfEmailSendToAnEmployee(sid)
    max_amount_of_emails_sent_to_an_employee = getMaxAmountOfEmailsSentToAnEmployee(sid)
    top_email_cc = getTopEmailCC
    top_email_recipient = getTopEmailRecipient
    time_spent_on_writing_emails = getTimeSpentOnWritingEmails
  end
end