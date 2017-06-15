class UserMailer < ActionMailer::Base
  default from: 'donotreply@mail.step-ahead.com'

  def reset_password_email(email, token, base_url)
    if Rails.env == 'development' || Rails.env == 'test'
      @base_url = 'http://localhost:3000'
    else @base_url = base_url
    end
    @link = @base_url + '/reset_password?token=' + token
    mail(subject: 'StepAhead - Reset Password', to: email)
  end
end
