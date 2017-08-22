include ExternalDataHelper

class SettingsController < ApplicationController
  def create_or_update_external_data
    authorize :setting, :admin?
    cid = current_user.company_id
    res = save_external_data(JSON.parse(params[:data]), cid)
    render json: res
  end
  
  def update_user_info
    authorize :setting, :index?

  	first_name = params[:first_name]
  	last_name = params[:last_name]
  	doc_encryption_pass = params[:reports_encryption_key]

		current_user.update_user_info(first_name, last_name, doc_encryption_pass)

  	head :ok
  end

  def edit_password
    authorize :setting, :index?
    old_password = params[:old_password]
    new_password = params[:new_password]

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
    
    session_timeout = params[:session_timeout]
    password_update_time_interval = params[:password_update_time]
    max_login_attempts = params[:login_attempts]
    required_password_chars = params[:required_characters]

    company.update_security_settings(session_timeout, password_update_time_interval, max_login_attempts, required_password_chars)
    head :ok
  end
end
