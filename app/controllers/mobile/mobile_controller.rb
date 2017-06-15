class Mobile::MobileController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  before_action :authenticate_user, except: [:show_mobile, :all_employees, :next, :keep_alive, :show_quest]
  before_action :set_locale

  PAGES = {
    home: { route: 'argggg', title: 'Title' }
  }

  def show_home
    goto_home
    redirect_to ''
  end


  def show_quest
    if params['desktop'] == 'true'
      show_desktop
    else
      show_mobile
    end
  end

  def show_mobile
    @token = JSON.parse(params[:data])['token']
    employee = Employee.find_by(token: @token)
    if employee
      @name = employee.first_name
      render 'mobile'
    else
      render text: 'Failed to load app, unkown employee.'
    end
  end

  def show_desktop
    @token = JSON.parse(params[:data])['token']
    employee = Employee.find_by(token: @token)
    if employee
      @name = employee.first_name
      render 'desk'
    else
      render text: 'Failed to load app, unkown employee.'
    end
  end

  def keep_alive
    counter = params[:counter]
    render json: { alive: counter }, status: 200
  end


  private

  def set_locale
    I18n.locale = :en
  end

  def goto_home
    @curr_page = PAGES[:home]
  end

  def authenticate_user
    redirect_to signin_path unless  logged_in?
  end
end
