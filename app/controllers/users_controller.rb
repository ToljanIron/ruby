require 'uri'
include ActionView::Helpers::SanitizeHelper

class UsersController < ApplicationController
  def user_details
    authorize :setting, :index?
    user = current_user
    company = Company.find(current_user.company_id)

    ret = {
        email: sanitize(user.email),
        first_name: sanitize(user.first_name),
        last_name: sanitize(user.last_name),
        user_type: user.role,
        reports_encryption_key: user.document_encryption_password,
        session_timeout: company.session_timeout,
        password_update_interval: company.password_update_interval,
        max_login_attempts: company.max_login_attempts,
        required_chars_in_password: company.get_required_password_chars,
        product_type: company.product_type,
        is_allowed_create_questionnaire: user.is_allowed_create_questionnaire
      }
    render json: ret, status: 200
  end

end
