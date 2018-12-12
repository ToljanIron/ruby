include SessionsHelper

class SessionsController < ApplicationController
  before_action :authenticate_user, except: [:signin, :api_signin, :forgot_password, :reset_password, :set_password]

  def signin
    authorize :application, :passthrough
    if current_user
      check_user_role(current_user)
    else
      render json: {res: 'Not Authenticated'}, status: 401
    end
  end

  def create
    authorize :application, :passthrough
    sanitize_alphanumeric(params[:session][:email])
    sanitize_alphanumeric(params[:session][:password])
    sanitize_alphanumeric(params[:session][:remember_me])

    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      log_in user
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      flash[:error] = nil
      check_user_role user
    else
      flash[:error] = 'error'
      render 'signin', layout: 'signin_layout'
    end
  end

  def destroy
    authorize :application, :passthrough
    sign_out if logged_in?
    redirect_to signin_url
  end

  def api_signin
    puts "@@@@@@@@@@@@@@@@@@@@@ 1"
    authorize :application, :passthrough
    sanitize_alphanumeric(params[:email])
    sanitize_alphanumeric(params[:password])
    sanitize_alphanumeric(params[:remember_me])

    puts "@@@@@@@@@@@@@@@@@@@@@ 2"
    user = User.find_by(email: params[:email].downcase)
    puts "@@@@@@@@@@@@@@@@@@@@@ 3"
    if user
    puts "@@@@@@@@@@@@@@@@@@@@@ 4"
      if authenticate_by_email_and_temporary_password(params[:email], params[:password])
    puts "@@@@@@@@@@@@@@@@@@@@@ 5"
        log_in user
        render json: { tmp_password: true }, status: 200
        return
      end
    end

    if user
    puts "@@@@@@@@@@@@@@@@@@@@@ 6"
      max_attempts = Company.find(user.company_id).max_login_attempts
      lock_delay   = CompanyConfigurationTable.lock_time_after_max_login_attempts
      if !user.can_login?(max_attempts, lock_delay)
    puts "@@@@@@@@@@@@@@@@@@@@@ 7"
        render json: { msg: 'Too many login attempts, locking down.'}, status: 550
        EventLog.log_event(event_type_name: 'LOGIN', message: "User: #{user.id} exceeded max login attempts")
        return
      end
    end

    puts "@@@@@@@@@@@@@@@@@@@@@ 8"
    logged = log_in user if user && user.authenticate(params[:password])
    if logged && params[:remember_me]
    puts "@@@@@@@@@@@@@@@@@@@@@ 9"
      remember(user)
    end
    puts "@@@@@@@@@@@@@@@@@@@@@ 10"
    unless logged
    puts "@@@@@@@@@@@@@@@@@@@@@ 11"
      flash[:error] = 'error'
      render json: { msg: 'failed to authenticate user' }, status: 550
      return
    end
    begin
    puts "@@@@@@@@@@@@@@@@@@@@@ 12"
      EventLog.log_event(event_type_name: 'LOGIN', message: "User: #{user.id} logged in")
      render json: payload(user), status: 200
      return
    rescue => e
      puts e.message
      puts e.backtrace
      flash[:error] = 'error'
      render json: { msg: 'failed to authenticate user' }, status: 550
    puts "@@@@@@@@@@@@@@@@@@@@@ 13"
      return
    end
    puts "@@@@@@@@@@@@@@@@@@@@@ 14"

  end

  def payload(user)
    return nil unless user and user.id

    company = Company.find(user.company_id)
    session_timeout = company.session_timeout
    timeout = 600
    timeout = 3600   if session_timeout == 1
    timeout = 7200   if session_timeout == 2
    timeout = 720000 if session_timeout == 3
    exp = Time.now.to_i + timeout

    return  {
      login_token: {
        auth_token: JsonWebToken.encode({user_id: user.id, exp: exp}),
        user: {id: user.id, email: user.email}
      },
      user_info: {
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
    }
  end

  def check_password
    authorize :application, :passthrough
    sanitize_alphanumeric(params[:session][:email])

    user = User.find_by(email: params[:session][:email].downcase)
    if user
      redirect_to email_send_path
    else
      flash[:error] = 'email invalid'
      redirect_to forgot_password_path
    end
  end

  def employee_page
    authorize :application, :passthrough
    render 'employee_page', layout: 'signin_layout'
  end

  def company_redirect
    authorize :application, :admin?
    sanitize_id(params[:session][:company_id])

    current_user.update_attribute(:company_id, params[:session][:company_id].to_i)
    redirect_to root_path
  end

  def email_send
  end

  private

  def check_user_role(user)
    # _TODO: domain check is dead code, should we remove it? US-12195
    if user.admin?
      services = services_with_missing_token(user)
      if services.length == 1
        redirect_to controller: 'clients', action: 'request_google_access', domain_id: services.first[:domain_id]
      elsif services.length > 1
        redirect_to domains_list_path
      else
        redirect_to admin_page_path
      end
    elsif user.hr?
      redirect_to root_path
    else
      redirect_to employee_page_path
    end
  end

  def services_with_missing_token(user)
    return []
  end
end
