# frozen_string_literal: true
require 'oj'
require 'oj_mimic_json'
include QuestionnaireHelper

class QuestionnaireController < ApplicationController
  protect_from_forgery with: :exception, except:[:add_unverfied_participant]
  before_action :authenticate_user, except: [:show_mobile,
                                             :all_employees,
                                             :all_groups,
                                             :get_next_question,
                                             :close_question,
                                             :update_question_replies,
                                             :keep_alive,
                                             :show_quest,
                                             :autosave,:add_unverfied_participant]
  # before_action :set_locale



  def all_employees
    authorize :application, :passthrough
    permitted = params.permit(:token)
    token = sanitize_alphanumeric(permitted[:token])
    raise "No such token" if token.nil?
    emps = hash_employees_of_company_by_token(token,false)
    if emps
      render json: emps, status: 200
    else
      render status: 500
    end
  end

  def all_groups
    authorize :application, :passthrough
    permitted = params.permit(:token)
    token = sanitize_alphanumeric(permitted[:token])
    raise "No such token" if token.nil?
     hash_groups_of_company_by_token(token,true)
    
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
    res[:is_contain_funnel_question] = is_contain_funnel_question(token)
    res = Oj.dump(res)
    render json: res
  end

  def update_question_replies
    authorize :application, :passthrough
    p = params.permit!
    token = sanitize_alphanumeric(p[:data][:token])
    raise "No such token" if token.nil?
    qd = get_questionnaire_details(token)

    ## We defer sanitizing to the helper where we rely on ActiveRecord to do that
    update_replies(qd[:qpid], params[:data])
    res = Oj.dump({status: 'ok'})
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

    msg = close_questionnaire_question(qd)

    res = (msg.nil? ? {status: 'ok'} : {status: 'fail', reason: msg});
    res = Oj.dump(res)
    render json: res
  end

  def add_unverfied_participant
    
    authorize :application, :passthrough
    token = sanitize_alphanumeric(params[:token])
   raise "No such token" if token.nil?
    permitted = request.params
    
    res=Questionnaire.create_unverified_participant_employee(permitted)
    
    unv_employee=res[:employee]
    unv_participant_id=res[:qpid]
    res = (res[:msg].empty? ? {status: 'ok',e_id:unv_employee.id, name:[unv_employee.first_name,unv_employee.last_name].join(" "),qpid:unv_participant_id, image_url:nil}: {status: 'fail', reason: msg});
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

  # def set_locale
  #   I18n.locale = :iw
  # end

  def goto_home
    @curr_page = PAGES[:home]
  end

  def authenticate_user
    redirect_to signin_path unless  logged_in?
  end
 
  def set_locale(extract_locale= :en)
    I18n.locale = extract_locale || :en
  end
end
