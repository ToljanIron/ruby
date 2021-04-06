class CloseQuestionnaireJob < ApplicationJob
  queue_as :close_questionnaire

  def perform(aq_id,email_address)
  	puts "===================CloseQuestionnaireJob=================="
    aq = Questionnaire.find(aq_id)
  	q_mode = "Successfuly"
    aq.freeze_questionnaire
    q_mode = "Failed in" if (aq.state != 'completed')
    puts "===================Send Mail=================="
    unless email_address.blank?
	    subject = 'Notification From StepAhead'
	    email_from = aq.email_from || 'gitiyaari@gmail.com'
	    user_name = ''
	    link = ''
	    email_text = "#{q_mode} close questionnaire: #{aq.name} - #{aq.id}"
	    em = ExampleMailer.sample_email(email_address,subject,email_from,user_name,link,email_text)
	    em.deliver
	  end
    # Do something later
  end
end
