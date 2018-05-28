module Mobile::SessionsHelper

  def log_in(user)
    session[:user_id] = user.id
  end

  def remember(user, long_expiration)
    user.remember
    cookies.signed[:user_id] = user.id
    expiration = long_expiration ? 20.years.from_now.utc : 20.minutes.from_now.utc
    cookies[:remember_token] = { value: user.remember_token, expires: expiration }
  end

  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def logged_in?
    !current_user.nil?
  end

  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end
end
