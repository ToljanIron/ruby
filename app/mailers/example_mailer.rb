class ExampleMailer < ActionMailer::Base

  FIRST_NAME = 'FIRST_NAME'
  LINK = 'LINK'

  def sample_email(to_address, subject, from_address, first_name, questionnaire_link, body_text)

    body_text.sub!(FIRST_NAME, first_name)
    body_text.sub!(LINK, questionnaire_link)
    @email_body = body_text

    mail(
      to: to_address,
      subject: subject,
      from: from_address
    )
  end
end
