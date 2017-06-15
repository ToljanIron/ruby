module ApplicationHelper
  def parse_response_by_question_id(str, q_id)
    res = {}
    json = (JSON.parse str)[q_id]
    res[:id] = json['responding_employee_id']
    res[:friends] = []
    json['responses'].map do |response|
      res[:friends].push(response['employee_id']) if response['response']
    end
    return res
  end

  def authenticate_user
    if params[:email] && authenticate_by_email_and_temporary_password(params[:email], params[:password])
      return true
    else
      redirect_to '/signin' unless logged_in?
      if params[:controller] == 'sessions' && params[:action] == 'destroy'
        return
      else
        render 'sessions/employee_page' if current_user && current_user.emp?
        # redirect_to root_path if current_user && current_user.hr?
      end
    end
  end

  def authenticate_by_email_and_temporary_password(email, password)
    @current_user = User.find_by(email: email)
    verified_user = @current_user.authenticate_by_tmp_password?(password) if @current_user
    verify_expired = User.where(email: email).not_expired.first if verified_user
    return false unless verify_expired
    session[:user_id] = User.find_by(email: email).id
    return true
  end
end
