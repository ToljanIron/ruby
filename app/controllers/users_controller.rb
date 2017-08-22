require 'uri'
class UsersController < ApplicationController
  skip_before_action :authenticate_user, only: [:user_forgot_password, :verify_password_token, :update_reset_new_password, :update_set_new_password]

  def user_forgot_password
    authorize :application, :passthrough
    begin
      flash[:error] = nil
      base_url = 'https://' + request.raw_host_with_port
      @user = User.find_by(email: params[:data].downcase)
      if @user.generate_password_reset_token
        mail = @user.send_reset_password_mail(base_url)
        if mail
          # flash[:error] = 'success'
          render json: { auth_token: @user[:auth_token], user_id: @user[:id] }, status: 200
        else
          flash[:error] = 'error'
          render json: { msg: 'error sending mail' }, status: 550
          return
        end
      else
        flash[:error] = 'error'
        render json: { msg: 'error generate token' }, status: 550
      end
    rescue
      flash[:error] = 'error'
      render json: { msg: 'failed to authenticate user' }, status: 550
      return
    end
  end

  def update_reset_new_password
    authorize :application, :passthrough
    flash[:token] = nil
    verify_token = User.verify_password_token(params[:token])
    unless verify_token
      flash[:token] = 'Password reset link has expired'
      redirect_to '/'
      return
    end
    flash[:password] = nil
    if (params[:password] != params[:password_confirmation])
      render json: { ans: false }, status: 401
      return
    end
    @current_user = User.find_by(password_reset_token: params[:token])
    if @current_user
      @current_user.update!(password: params[:password], password_confirmation: params[:password_confirmation], password_reset_token_expiry: DateTime.now)
      flash[:password] = 'Password changed successfully'
      session.delete(:user_id)
      render json: { ans: true, user_id: @current_user }, status: 200
    else
      flash[:password_error] = 'Error on changing password'
      sign_out if logged_in?
      render 'sessions/signin', layout: 'signin_layout'
    end
  end

  def update_set_new_password
    authorize :application, :passthrough
    flash[:password] = nil
    if (params[:password] != params[:password_confirmation])
      render json: { ans: false }, status: 401
      return
    end
    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
    if @current_user
      @current_user.update!(password: params[:password], password_confirmation: params[:password_confirmation], tmp_password_expiry: DateTime.now, tmp_password: nil)
      flash[:password] = 'Password changed successfully'
      session.delete(:user_id)
      render json: { ans: true, user_id: @current_user }, status: 200
    else
      flash[:password_error] = 'Error on changing password'
      sign_out if logged_in?
      render 'sessions/signin', layout: 'signin_layout'
    end
  end

  def user_details
    authorize :application, :passthrough
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
