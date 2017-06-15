class ExampleMailer < ActionMailer::Base
  default from: 'donotreply@mail.step-ahead.com'

  def sample_email(msg)
    @msg = msg
    employee = QuestionnaireParticipant.find(msg.questionnaire_participant_id).employee
    mail(to: employee.email, subject: 'פיילוט StepAhead - סקר')
  end
end
