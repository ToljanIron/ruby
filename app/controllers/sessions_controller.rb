include SessionsHelper

class SessionsController < ApplicationController
  before_action :authenticate_user, except: [:signin, :api_signin, :forgot_password, :reset_password, :set_password]

  def signin
    authorize :application, :passthrough
    if current_user
      check_user_role(current_user)
    else
      render json: {res: 'Not Authenticated'}, status: 401 if v3_login?
      render 'signin', layout: 'signin_layout' if !v3_login?
    end
  end

  def create
    authorize :application, :passthrough
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
    authorize :application, :passthrough
    user = User.find_by(email: params[:email].downcase)
    if user
      if authenticate_by_email_and_temporary_password(params[:email], params[:password])
        log_in user
        render json: { tmp_password: true }, status: 200
        return
      end
    end
    logged = log_in user if user && user.authenticate(params[:password])
    if logged && params[:remember_me]
      remember(user)
    end
    unless logged
      flash[:error] = 'error'
      render json: { msg: 'failed to authenticate user' }, status: 550
      return
    end
    begin
      render json: payload(user), status: 200 if v3_login?
      render json: { token: user.remember_token }, status: 200 if !v3_login?
      return
    rescue
      flash[:error] = 'error'
      render json: { msg: 'failed to authenticate user' }, status: 550
      return
    end
  end

  def payload(user)
    return nil unless user and user.id

    return  {
        login_token: {
            auth_token: JsonWebToken.encode({user_id: user.id}),
            user: {id: user.id, email: user.email}
          },
        user_info: {
            email: user.email,
            first_name: user.first_name,
            last_name: 'NA',
            user_type: user.role,
            reports_encryption_key: user.document_encryption_password
          }
      }
  end

  def forgot_password
    authorize :application, :passthrough
    render 'forgot_password', layout: 'signin_layout'
  end

  def set_password
    authorize :application, :passthrough
    if !logged_in?
      redirect_to signin_path
      return
    end
    render 'set_password', layout: 'signin_layout'
  end

  def reset_password
    authorize :application, :passthrough
    flash[:token] = nil
    verify_token = User.verify_password_token(params[:token])
    unless verify_token
      flash[:token] = 'Password reset link has expired'
      redirect_to '/'
      return
    end
    flash[:password] = nil
    render 'reset_password', layout: 'signin_layout'
  end

  def check_password
    authorize :application, :passthrough
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
