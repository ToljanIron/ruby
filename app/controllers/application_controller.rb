# frozen_string_literal: true
include ApplicationHelper
include SessionsHelper
include Pundit
include CdsUtilHelper
include SanitizeHelper
include Asspects
require 'yaml'

class ApplicationController < ActionController::Base

  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  DYNAMIC_LOCALE = false

  if false
    protect_from_forgery with: :null_session
  end

  around_action :global_error_handler
 # skip_around_action :global_error_handler, :only => [:user_not_authorized]

  #before_action :set_locale, except: [:signin, :api_signin]

  # check_authorization
  before_action :authenticate_user, except: [:show_mobile, :robots, :receive_and_respond]

  # Verify all actions pass authorization.
  after_action :verify_authorized

  def show_mobile
    authorize :application, :passthrough

    @token = sanitize_alphanumeric( params['token'] )
    qp = authenticate_questionnaire_participant(@token)

    if qp
      # Added message when questionnaire is closed - Michael K. - 12.9.17
      questionnaire = Questionnaire.find(qp.questionnaire_id)
      if (questionnaire.state === 'completed')
        response.headers['X-Frame-Options'] = 'ALLOWALL'
        render plain: 'Questionnaire is closed.'
	      return
      end
      I18n.locale = qp.gt_locale
      locale = I18n.locale
      @name = qp.employee.first_name          if qp.participant_type == 'participant'
      @name = qp.questionnaire.test_user_name if qp.participant_type == 'tester'
      @dict = load_dict(locale)
      if (params['desktop'] == 'true' || !mobile?) && params['mobile'] != 'true'
        puts "@@@@@@@@@@@@@@@@@@ 2"
        render 'desk', layout: 'mobile_application'
      else
        puts "@@@@@@@@@@@@@@@@@@ 3"
        response.headers['X-Frame-Options'] = 'ALLOWALL'
        render 'mobile', layout: 'mobile_application'
      end
    else
      render plain: 'Failed to load app, unkown employee.'
    end
  end

  def robots
    authorize :application, :passthrough
    user_agents = '*'
    disallow = '/'
    res = ''
    if ENV['BLOCK_BOTS']
      res = [
        "User-agent: #{user_agents} # we don't like those bots",
        "Disallow: #{disallow} # block bots access to those paths"
      ].join("\n")
    end
    render text: res, layout: false, content_type: 'text/plain'
  end

  private

  def mobile?
    (request.user_agent.downcase =~ /mobile|ip(hone|od|ad)|android|blackberry|iemobile|kindle|netfront|silk-accelerated|(hpw|web)os|fennec|minimo|opera m(obi|ini)|blazer|dolfin|dolphin|skyfire|zune/) && !(request.user_agent.downcase =~ /ipad|kindle|silk/)
  end

  def set_locale
    if DYNAMIC_LOCALE
      cid = gt_cid
      return :en if cid.nil?
      cache_key = "LOCAL-company_id-#{cid}"
      locale = cache_read(cache_key)
      if locale.nil?
        locale = CompanyConfigurationTable.get_company_locale(cid)
        cache_write(cache_key, locale)
      end
      I18n.locale = locale
    else
      I18n.locale = :en
    end
  end

  def gt_cid
    return current_user.company_id unless current_user.nil?
    data = params[:data]
    return nil if data.nil?
    token = sanitize_alphanumeric( JSON.parse(data)['token'] )
    qp = Mobile::Utils.authenticate_questionnaire_participant(token)
    return nil if qp.nil?
    emp = qp.employee
    return nil if emp.nil?
    return emp.company_id
  end

  def global_error_handler
    yield
  rescue => e
    logger.error "EXCEPTION: #{e}"
    logger.error e.backtrace.join("\n")
    EventLog.log_event(event_type_name: 'ERROR', message: e.message)
    render json: Oj.dump(error: e.to_s)
    raise e
  end

  def load_dict(locale)
    path = Rails.root.join("config/locales", "#{locale.to_s}.yml").to_s
    dict = YAML.load_file(path)
    return dict[locale.to_s].to_json
  end

  def user_not_authorized
    Rails.logger.info "You are not authorized to perform this action." 
  end

end
