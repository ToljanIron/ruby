require 'uri'
class UsersController < ApplicationController
  def user_details
    authorize :setting, :index?
    user = current_user
    company = Company.find(current_user.company_id)

    ret = {
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        user_type: user.role,
        reports_encryption_key: user.document_encryption_password,
        session_timeout: company.session_timeout,
        password_update_interval: company.password_update_interval,
        max_login_attempts: company.max_login_attempts,
        required_chars_in_password: company.get_required_password_chars
      }
    render json: ret, status: 200
  end
end
