# frozen_string_literal: true
include ApplicationHelper
include Mobile::Utils
include SessionsHelper
include Pundit
include CdsUtilHelper

class ApplicationController < ActionController::Base
  DYNAMIC_LOCALE = false

  if ENV['USE_V3_LOGIN'] == 'false'
    protect_from_forgery with: :null_session
  end

  around_action :global_error_handler

  before_action :set_locale, except: [:signin, :api_signin]

  # check_authorization
  before_action :authenticate_user, except: [:show_mobile, :robots, :receive_and_respond]

  # Verify all actions pass authorization.
  after_action :verify_authorized

  def show_v2_app
    authorize :application, :passthrough
    render 'v2_app', layout: 'v2_application'
  end

  def show_mobile
    authorize :application, :passthrough
    # @token = JSON.parse(params[:data])['token']
    @token = params['token']
    qp = Mobile::Utils.authenticate_questionnaire_participant(@token)
    if qp
      I18n.locale = qp.gt_locale
      @name = qp.employee.first_name
      if params['desktop'] == 'true' || !mobile?
        render 'desk', layout: 'mobile_application'
      else
        render 'mobile', layout: 'mobile_application'
      end
    else
      render text: 'Failed to load app, unkown employee.'
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
    token = JSON.parse(data)['token']
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
end
