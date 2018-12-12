class SettingsController < ApplicationController
  def update_user_info
    authorize :setting, :update?

  	first_name = params[:first_name].sanitize_is_string_with_space
  	last_name = params[:last_name].sanitize_is_string_with_space

  	doc_encryption_pass = params[:reports_encryption_key].sanitize_is_alphanumeric

		current_user.update_user_info(first_name, last_name, doc_encryption_pass)

  	head :ok
  end

  def edit_password
    authorize :setting, :update?
    old_password = params[:old_password].sanitize_is_alphanumeric
    new_password = params[:new_password].sanitize_is_alphanumeric

    success = current_user.update_password(old_password, new_password)
    message = success ? 'Password updated successfully' : 'Wrong password'

    render json: { message: message }, status: success ? 200 : 500
  end

  def update_security_settings
    authorize :setting, :admin?

    company = Company.find(current_user.company_id)

    if(company.nil?)
      render json: { message: 'Cannot find company' }, status:  500
      return
    end

    session_timeout = params[:session_timeout].sanitize_integer
    password_update_time_interval = params[:password_update_time].sanitize_integer
    max_login_attempts = params[:login_attempts].sanitize_integer
    required_password_chars = params[:required_characters].sanitize_has_no_whitespace

    company.update_security_settings(session_timeout, password_update_time_interval, max_login_attempts, required_password_chars)
    head :ok
  end

  def get_config_params
    authorize :setting, :update?
    ret = {
      incomingEmailToTime: CompanyConfigurationTable.incoming_email_to_time,
      outgoingEmailToTime: CompanyConfigurationTable.outgoing_email_to_time,
      product_type: Company.find(current_user.company_id).product_type
    }
    render json: ret, statatus: 200
  end
end
