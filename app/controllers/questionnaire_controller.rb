# frozen_string_literal: true
require 'oj'
require 'oj_mimic_json'
include QuestionnaireHelper

class QuestionnaireController < ApplicationController
  protect_from_forgery with: :exception
  before_action :authenticate_user, except: [:show_mobile,
                                             :all_employees,
                                             :get_next_question,
                                             :close_question,
                                             :keep_alive,
                                             :show_quest,
                                             :autosave]
  before_action :set_locale

  def all_employees
    authorize :application, :passthrough
    permitted = params.permit(:token)
    token = sanitize_alphanumeric(permitted[:token])
    raise "No such token" if token.nil?
    emps = hash_employees_of_company_by_token(token)
    if emps
      render json: emps, status: 200
    else
      render status: 500
    end
  end

  def get_next_question
    authorize :application, :passthrough
    p = params.permit!
    token = sanitize_alphanumeric(params[:data][:token])
    raise "No such token" if token.nil?

    is_desktop = sanitize_boolean(params[:data][:desktop])
    is_desktop = true  if is_desktop == 'true'  || is_desktop == true
    is_desktop = false if is_desktop == 'false' || is_desktop == false

    res = get_questionnaire_details(token)
    reps = get_question_participants(token, res, is_desktop)
    res[:replies] = reps[:replies]
    res[:client_min_replies] = reps[:client_min_replies]
    res[:client_max_replies] = reps[:client_max_replies]

    res = Oj.dump(res)
    render json: res
  end

  def close_question
    authorize :application, :passthrough
    token = sanitize_alphanumeric(params[:data][:token])
    raise "No such token" if token.nil?
    qd = get_questionnaire_details(token)

    ## Update replies
    ## We defer sanitizing to the helper where we rely on ActiveRecord to do that
    update_replies(qd[:qpid], params[:data])

    msg = close_questionnaire_question(token, qd)

    res = (msg.nil? ? {status: 'ok'} : {status: 'fail', reason: msg});
    res = Oj.dump(res)
    render json: res
  end

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
      puts "Did not manage to find employee from token: #{@token}"
      render plain: 'Failed to load app, unkown employee.'
    end
  end

  def show_desktop
    @token = JSON.parse(params[:data])['token']
    employee = Employee.find_by(token: @token)
    if employee
      @name = employee.first_name
      render 'desk'
    else
      puts "Did not manage to find employee from token: #{@token}"
      render plain: 'Failed to load app, unkown employee.'
    end
  end

  def keep_alive
    authorize :application, :passthrough
    permitted = params.permit(:counter)
    counter = permitted[:counter]
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
