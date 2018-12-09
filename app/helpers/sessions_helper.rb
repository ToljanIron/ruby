module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.undigest_token
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  attr_writer :current_user

  def current_user
    if (user_id = session[:user_id])
      if User.where(id: session[:user_id]).not_expired.first.nil? || User.where(id: session[:user_id]).not_expired.first
        @current_user ||= User.find_by(id: user_id)
      end
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  def signed_in?
    !current_user.nil?
  end

  def add_company
    @companies = Company.all
  end

  def add_company_for_hr
    company = Company.find(current_user.company_id)
    @companies = "{produt_type: '#{company.product_type}'}"
    return  @Companies
  end

  def employee_role?
    !current_user.nil? && current_user.employee?
  end

  def client_auth(token)
    return if token.nil?
    ApiClient.authenticate_client(token)
  end

  def sign_out
    forget current_user
    session.delete(:user_id)
    self.current_user = nil
  end

  def display_emails?
    @should_display_emails = CompanyConfigurationTable::is_investigation_mode?
  end

  def get_company_type
    return Company.find(current_user.company_id).product_type
  end
end

def log_in(user)
  session[:user_id] = user.id
end

def current_user
  return current_user_v3
end

def current_user_v3
  unless user_id_in_token?
    puts "JWT could not find user in token - not authenticated"
    return
  end
  @current_user = User.find(auth_token(http_token)[:user_id])
rescue JWT::VerificationError, JWT::DecodeError
  puts "JWT exception - not authenticated"
end

def http_token
  @http_token ||= if request.headers['Authorization'].present?
    request.headers['Authorization'].split(' ').last
  end
end

def auth_token(ht)
  @auth_token ||= JsonWebToken.decode(ht)
end

def user_id_in_token?
  ht = http_token
  at = auth_token(ht)
  ht && at && at[:user_id].to_i
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
