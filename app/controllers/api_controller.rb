class ApiController < ActionController::Base
  include SessionsHelper

  private

  def authenticate_user
    token = request.headers['token'] || params['token']
    render json: { error: 'ApiController: Failed! to authenticated api user', token: token, status: 500 } if client_auth(token).nil?
  end
end
